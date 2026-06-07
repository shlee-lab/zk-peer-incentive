# ZK Reward Relation

This PoC verifies lottery reward-computation correctness for inverse-frequency
peer-agreement rewards over hidden binary reports and private nonces.

It does not rewrite MACI. The official MACI baseline is exercised separately,
and this relation is the reward sidecar proof attached to a MACI-derived final
poll state. The reward proof only shows that the announced payouts are
consistent with hidden reports and the announced reward rule.

## Public Inputs

- `N = 8`: fixed voter count for this circuit instance.
- `stakes[i]`: public stake for voter `i`.
- `peer(i) = i+1 mod N`: fixed ring peer assignment.
- `smoothing`: smoothing parameter `a`.
- `kappa`: reward scale.
- `scale`: integer scale used for fixed-point payouts.
- `payout[i]`: public lottery payout for voter `i`.
- `recipient[i]`: public payout address for voter `i`, encoded as a 160-bit
  field element.
- `disputeId`: public dispute or MACI poll context.
- `finalStateRoot`: public reward sidecar root. In the MACI integration plan this
  is `finalRewardStateRoot`.
- `rewardRandomness`: public draw entropy registered for this final reward
  state.
- `rhoTau`: public jackpot payout.

The current circuit keeps reports/nonces private and binds them to a MACI reward
sidecar root with fixed-position Merkle openings.

## Private Witness

- `reports[i] in {0,1}`.
- `nonces[i]`.
- `maciStateIndices[i]`.
- `voterIds[i]`.
- `nonceCommitments[i]`.
- `merklePathElements[i][d]`.
- `expectedScaled[i]`.
- Remainder witnesses for fixed-point division.

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

The expected scaled reward is:

$$
\mathrm{expectedScaled}_i =
\left\lfloor \tau_i\cdot \mathrm{scale}\right\rfloor.
$$

The lottery seed is:

$$
s = H(nonce_0,\ldots,nonce_{N-1}, disputeId, finalStateRoot, rewardRandomness).
$$

The voter draw is:

$$
u_i = low32(H(s, i)).
$$

The public payout is:

$$
\mathrm{payout}_i =
\begin{cases}
\rhoTau, & u_i\rhoTau < \mathrm{expectedScaled}_i2^{32},\\
0, & \text{otherwise.}
\end{cases}
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

6. Lottery payout:

   $$
   draw_i\rhoTau < \mathrm{expectedScaled}_i2^{32}
   $$

   iff the public payout equals `rhoTau`; otherwise it equals zero.

7. Reward sidecar nonce opening:

   $$
   nonceCommitment_i = H(nonce_i, 0)
   $$

8. Reward sidecar final-state inclusion:

   $$
   leaf_i = H(maciStateIndex_i, voterId_i, r_i, nonceCommitment_i, stake_i, recipient_i)
   $$

   and the fixed-position Merkle path for index `i` must reconstruct the public
   `finalStateRoot`.

9. Public range checks:

   - `stakes[i]`, `smoothing`, `kappa`, and `scale` fit in 32 bits.
   - `rhoTau`, `payout[i]`, and `expectedScaled[i]` fit in 64 bits.
   - `recipient[i]` fits in 160 bits.
   - `rem_i` fits within the 128-bit comparison domain.

The circuit uses `circomlib` Poseidon, bit decomposition, and less-than gadgets.

## Security Claim

Given a sound and zero-knowledge proof system, a valid proof implies that the
public lottery payouts match the hidden reports and nonces under the announced
reward rule and public context, and that those same reports/nonces open to the
nonce commitments and reports included in the public reward sidecar root. The
proof does not itself reveal the reports or nonces.

The proof also binds payout recipient addresses to the sidecar leaves. It does
not prove that the sidecar's recipient address mapping was produced by MACI; the
current integration treats that mapping as an experimental adapter input.

Lottery fairness additionally depends on `rewardRandomness` being generated
after the final reward state is fixed and without coordinator control. A
production design should use a VRF, randomness beacon, or commit-reveal flow.

The proof does not show that voters exerted effort. Effort is induced by the
mechanism-design incentive analysis, not cryptographically proven.
