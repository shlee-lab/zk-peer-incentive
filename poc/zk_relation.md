# ZK Reward Relation

This PoC verifies fixed-budget reward-computation correctness for
inverse-frequency peer-agreement rewards over hidden binary reports and private
nonces.

MACI itself remains unmodified. The official MACI baseline is exercised
separately, and this relation is the reward sidecar proof attached to a
MACI-derived final poll state. The reward proof checks that the announced
payouts are consistent with hidden reports and the announced reward rule.

## Public Inputs

- `N = 8`: fixed voter count for this circuit instance.
- `stakes[i]`: public stake for voter `i`.
- `peer(i) = i+1 mod N`: fixed ring peer assignment.
- `smoothing`: smoothing parameter `a`.
- `kappa`: reward scale.
- `scale`: integer scale used for fixed-point scores.
- `rhoTau`: lottery ticket payout scale and threshold denominator.
- `payout[i]`: public fixed-budget payout for voter `i`.
- `recipient[i]`: public payout address for voter `i`, encoded as a 160-bit
  field element.
- `disputeId`: public dispute or MACI poll context.
- `finalStateRoot`: public reward sidecar root. In the MACI integration plan this
  is `finalRewardStateRoot`.
- `rewardBudget`: public total payout budget.

The current circuit keeps reports/nonces private and binds them to a MACI reward
sidecar root with fixed-position Merkle openings.

## Private Witness

- `reports[i] in {0,1}`.
- `nonces[i]`: in the full MACI experiment, this is the encrypted MACI
  `VoteCommand.salt` value for voter `i`.
- `maciStateIndices[i]`.
- `voterIds[i]`.
- `nonceCommitments[i]`.
- `merklePathElements[i][d]`.
- `expectedScaled[i]`.
- Remainder witnesses for fixed-point scoring and fixed-budget allocation.

## Reward Rule

For voter `i`, define the leave-one-out denominator:

$$
D_i = \sum_{j\ne i} w_j + 2a.
$$

Define the smoothed report-1 numerator:

$$
N_i = \sum_{j\ne i} w_j r_j + a.
$$

The report normalizer is:

$$
\tilde w_i(1)=\frac{N_i}{D_i},
\qquad
\tilde w_i(0)=\frac{D_i-N_i}{D_i}.
$$

Agreement with the assigned peer is:

$$
\mathrm{eq}_i = 1-(r_i-r_{\mathrm{peer}(i)})^2.
$$

The exact reward is:

$$
\tau_i =
\begin{cases}
\kappa w_i \mathrm{eq}_i D_i/N_i, & r_i=1,\\
\kappa w_i \mathrm{eq}_i D_i/(D_i-N_i), & r_i=0.
\end{cases}
$$

The expected scaled score is:

$$
\mathrm{expectedScaled}_i =
\left\lfloor \tau_i\cdot \mathrm{scale}\right\rfloor.
$$

The lottery seed is:

$$
\mathrm{seed}=H(nonce_0,\ldots,nonce_{N-1},disputeId,finalStateRoot).
$$

Each voter draw is:

$$
u_i=\mathrm{low}_{32}(H(\mathrm{seed}, i)).
$$

The lottery winner bit is:

$$
\mathrm{win}_i =
\begin{cases}
1, & u_i \rhoTau < \mathrm{expectedScaled}_i 2^{32},\\
0, & \text{otherwise.}
\end{cases}
$$

The fixed-budget allocation score is:

$$
\alpha_i=\mathrm{scale}+\mathrm{win}_i\rhoTau.
$$

The public payouts are then normalized to a fixed budget `B = rewardBudget`:

$$
\mathrm{payout}_i \approx
\frac{B\alpha_i}{\sum_j \alpha_j}.
$$

For integer arithmetic, the first `N-1` payouts are floored:

$$
\mathrm{payout}_i=
\left\lfloor
\frac{B\alpha_i}{\sum_j\alpha_j}
\right\rfloor
\qquad 0\le i<N-1.
$$

The final payout receives the rounding residue:

$$
\mathrm{payout}_{N-1}=B-\sum_{i=0}^{N-2}\mathrm{payout}_i.
$$

## Circuit Checks

1. Binary reports:

   $$
   r_i(r_i-1)=0.
   $$

2. Leave-one-out normalizer:

   $$
   D_i = \sum_{j\ne i} w_j + 2a,
   \qquad
   N_i = \sum_{j\ne i} w_j r_j + a.
   $$

3. Agreement:

   $$
   \mathrm{eq}_i=1-(r_i-r_{\mathrm{peer}(i)})^2.
   $$

4. Report-specific denominator:

   $$
   B_i = r_iN_i+(1-r_i)(D_i-N_i).
   $$

5. Fixed-point payout division:

   $$
   \kappa w_i\mathrm{eq}_iD_i\mathrm{scale}
   =
   \mathrm{expectedScaled}_iB_i+\mathrm{rem}_i.
   $$

   with

   $$
   0\le \mathrm{rem}_i < B_i.
   $$

6. Lottery draw:

   $$
   \mathrm{seed}=H(nonce_0,\ldots,nonce_{N-1},disputeId,finalStateRoot),
   \qquad
   u_i=\mathrm{low}_{32}(H(\mathrm{seed}, i)).
   $$

   The circuit enforces:

   $$
   \mathrm{win}_i =
   [u_i\rhoTau < \mathrm{expectedScaled}_i2^{32}]
   $$

   and requires:

   $$
   \mathrm{expectedScaled}_i \le \rhoTau.
   $$

7. Fixed-budget allocation:

   $$
   B\alpha_i=\mathrm{payout}_i\sum_j\alpha_j+\mathrm{allocRem}_i
   \qquad 0\le i<N-1
   $$

   with

   $$
   0\le \mathrm{allocRem}_i<\sum_j\alpha_j.
   $$

   The circuit also enforces:

   $$
   \sum_i\mathrm{payout}_i=B.
   $$

8. Reward sidecar nonce opening:

   $$
   nonceCommitment_i = H(nonce_i, 0)
   $$

9. Reward sidecar final-state inclusion:

   $$
   leaf_i = H(maciStateIndex_i, voterId_i, r_i, nonceCommitment_i, stake_i, recipient_i)
   $$

   and the fixed-position Merkle path for index `i` must reconstruct the public
   `finalStateRoot`.

10. Public range checks:

   - `stakes[i]`, `smoothing`, `kappa`, and `scale` fit in 32 bits.
   - `rhoTau`, `rewardBudget`, `payout[i]`, and `expectedScaled[i]` fit in 64 bits.
   - `recipient[i]` fits in 160 bits.
   - `rem_i` fits within the 128-bit comparison domain.

The circuit uses `circomlib` Poseidon, bit decomposition, and less-than gadgets.

## Proof Claim and Scope

Given a sound and zero-knowledge proof system, a valid proof implies that the
public fixed-budget lottery payouts match the hidden reports and nonces under
the announced reward rule and public context, and that those same reports/nonces
open to the nonce commitments and reports included in the public reward sidecar
root. The proof does not itself reveal the reports or nonces.

The proof also binds payout recipient addresses to the same sidecar leaves. The
MACI-to-recipient adapter, command-salt nonce bridge, and user-effort incentive
model are application-layer parts of the prototype rather than separate claims
inside this circuit. A deeper MACI integration could add a dedicated reward
nonce field to the MACI command and circuits, but that would require new MACI
zkeys.
