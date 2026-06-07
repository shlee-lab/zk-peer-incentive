# ZK Reward Relation

This PoC verifies lottery reward-computation correctness for inverse-frequency
peer-agreement rewards over hidden binary reports and private nonces.

It does not implement full MACI. It assumes a MACI-like voting layer has already
collected encrypted or committed reports. The reward proof only shows that the
announced payouts are consistent with hidden reports and the announced reward
rule.

## Public Inputs

- `n`: fixed voter count for the circuit instance.
- `stakes[i]`: public stake for voter `i`.
- `peer[i]`: public peer assignment for voter `i`.
- `smoothing`: smoothing parameter `a`.
- `kappa`: reward scale.
- `scale`: integer scale used for fixed-point payouts.
- `payout[i]`: public lottery payout for voter `i`.
- `disputeId`: public dispute context.
- `stateRoot`: public state-root context. In v1 this is not yet Merkle-bound to
  the reports/nonces.
- `rhoTau`: public jackpot payout.

The v1 circuit keeps reports/nonces private but does not bind them to final-state
commitments. v2 should add a MACI-like final-state inclusion relation.

## Private Witness

- `reports[i] in {0,1}`.
- `nonces[i]`.
- Quotient/remainder witnesses for fixed-point division.

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
s = H(nonce_0,\ldots,nonce_{N-1}, disputeId, stateRoot).
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

The circuit uses `circomlib` Poseidon, bit decomposition, and less-than gadgets.

## Security Claim

Given a sound and zero-knowledge proof system, a valid v1 proof implies that the
public lottery payouts match the hidden reports and nonces under the announced
reward rule and public context. The proof does not itself reveal the reports or
nonces.

The proof does not show that voters exerted effort. Effort is induced by the
mechanism-design incentive analysis, not cryptographically proven.
