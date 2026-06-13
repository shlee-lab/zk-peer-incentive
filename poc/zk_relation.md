# ZK Reward Relation

This circuit is the reward sidecar relation for the MACI integration prototype.
It proves coordinate-wise Bernoulli peer-prediction payouts over hidden binary
reports, while binding those reports to a public reward sidecar Merkle root.

MACI remains unmodified. MACI proves encrypted vote processing and tallying;
this relation proves only reward correctness from the committed final reward
state.

## Public Inputs

For the current integrated circuit, `N = 8` and the public inputs are:

- `payouts[i]`: public payout for voter `i`, constrained to `0` or `rhoTau`.
- `recipients[i]`: public recipient address for coordinate `i`, encoded as a
  160-bit field element.
- `stakes[i]`: public stake for coordinate `i`.
- `smoothing`: smoothing parameter `a`.
- `kappa`: peer-prediction reward scale.
- `scale`: fixed-point scale for score computation.
- `rhoTau`: per-winner payout amount and threshold denominator.
- `disputeId`: dispute id or MACI poll id.
- `finalStateRoot`: public reward sidecar Merkle root.
- `rewardBudget`: expected-payout cap.
- `gammaScaled`: lower clamp, `floor(gamma * 2^LOTTERY_BITS)`.
- `randomSeed`: external randomness fixed after `finalStateRoot` registration.

The public signal order is:

```text
payouts[0..7]
recipients[8..15]
stakes[16..23]
smoothing[24]
kappa[25]
scale[26]
rhoTau[27]
disputeId[28]
finalStateRoot[29]
rewardBudget[30]
gammaScaled[31]
randomSeed[32]
```

## Private Witness

The witness contains:

- `reports[i] in {0,1}`.
- `nonces[i]`, used only to open `nonceCommitments[i]`.
- `maciStateIndices[i]`.
- `voterIds[i]`.
- `nonceCommitments[i]`.
- `merklePathElements[i][d]`.
- `expectedScaled[i]`.
- `rewardRemainders[i]`.
- `rawThresholds[i]`.
- `thresholdRemainders[i]`.

## Reward State Binding

For every coordinate, the circuit checks:

$$
nonceCommitment_i = H(nonce_i, 0).
$$

It then hashes the reward sidecar leaf:

$$
leaf_i =
H(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i, recipient_i).
$$

The fixed-position Merkle path for index `i` must reconstruct the public
`finalStateRoot`. This closes the earlier v0 gap: the current relation does not
merely compute rewards from private reports; it proves that those private
reports, nonce commitments, stakes, and recipients are included in the registered
reward state root.

## Peer-Prediction Score

The peer graph is a ring:

$$
peer(i) = (i+1) \bmod N.
$$

For voter `i`, define the leave-one-out denominator:

$$
D_i = \sum_{j\ne i} w_j + 2a.
$$

Define the smoothed report-1 numerator:

$$
N_i = \sum_{j\ne i} w_j r_j + a.
$$

The report-specific denominator is:

$$
B_i = r_i N_i + (1-r_i)(D_i - N_i).
$$

Agreement with the assigned peer is:

$$
eq_i = 1-(r_i-r_{peer(i)})^2.
$$

The integer expected score witness is constrained by:

$$
\kappa w_i eq_i D_i scale
= expectedScaled_i B_i + rem_i,
$$

with:

$$
0 \le rem_i < B_i.
$$

Equivalently, `expectedScaled_i` is the fixed-point floor of the smoothed
inverse-frequency peer-agreement score.

## Bernoulli Lottery

The application layer fixes `randomSeed` only after `finalStateRoot` has been
registered. The circuit derives the lottery seed as:

$$
seed = H(disputeId, finalStateRoot, randomSeed).
$$

Each coordinate uses a separate pseudorandom draw:

$$
u_i = low_{32}(H(seed, i)).
$$

The unclamped threshold is:

$$
raw_i =
\left\lfloor
\frac{expectedScaled_i 2^{32}}{rhoTau}
\right\rfloor.
$$

The circuit proves the quotient/remainder relation:

$$
expectedScaled_i 2^{32}
= raw_i rhoTau + thresholdRem_i,
$$

with:

$$
0 \le thresholdRem_i < rhoTau.
$$

It then enforces the probability clamp:

$$
threshold_i =
\min(2^{32}-gammaScaled,\max(gammaScaled, raw_i)).
$$

The winner bit is:

$$
win_i = [u_i < threshold_i].
$$

The public payout is finally constrained as:

$$
payout_i = win_i \cdot rhoTau.
$$

Thus every public payout coordinate is binary: `0` or `rhoTau`.

## Budget Meaning

The circuit does not force exact budget exhaustion. Instead it caps expected
payout mass:

$$
\sum_i threshold_i \cdot rhoTau
\le rewardBudget \cdot 2^{32}.
$$

In the current contract flow, the pool is funded for maximum exposure
`N * rhoTau`. Any unclaimed or unpaid remainder is handled by the pool contract,
not by the proof relation.

## Circuit Checks

The circuit enforces:

1. binary reports;
2. public range checks for stakes, recipients, payouts, and parameters;
3. nonce commitment openings;
4. Merkle inclusion in `finalStateRoot` for every coordinate;
5. leave-one-out score arithmetic;
6. threshold quotient/remainder arithmetic;
7. gamma lower and upper clamp;
8. independent coordinate draws `H(seed, i)`;
9. binary payout equation `payout_i = win_i * rhoTau`;
10. expected-payout cap against `rewardBudget`.

The implementation uses `circomlib` Poseidon, bit decomposition, and comparison
gadgets. The draw independence is computational pseudorandomness from Poseidon,
not statistical independence.

## Proof Claim and Scope

Given a sound and zero-knowledge proof system, a valid proof implies that the
public payout vector follows the announced Bernoulli lottery rule for hidden
reports that are included in the public reward sidecar root, and that recipient
addresses are bound to the same root.

The proof does not implement MACI, prove human effort, choose a production
randomness policy, or provide Sybil resistance. Those are application-layer
assumptions outside this reward relation.
