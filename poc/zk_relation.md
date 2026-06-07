# ZK Reward Relation

This PoC verifies reward-computation correctness for inverse-frequency
peer-agreement rewards over hidden binary reports.

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
- `payoutScaled[i]`: public scaled payout for voter `i`.

The v0 circuit keeps reports private but does not bind them to commitments. A
production version should add a commitment/MACI consistency relation.

## Private Witness

- `reports[i] in {0,1}`.
- Optional quotient/remainder witnesses for fixed-point division.

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

The public scaled payout is:

$$
\mathrm{payoutScaled}_i =
\left\lfloor \tau_i\cdot \mathrm{scale}\right\rfloor.
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
   \mathrm{payoutScaled}_iB_i+\mathrm{rem}_i.
   $$

   with

   $$
   0\le \mathrm{rem}_i < B_i.
   $$

The remainder range check is the only nontrivial low-level component. The
included Circom draft wires the arithmetic relation and leaves a bounded
less-than gadget as the implementation detail to instantiate with `circomlib`
or a local bit-decomposition gadget.

## Security Claim

Given a sound and zero-knowledge proof system, a valid proof implies that the
public payouts match the hidden reports under the announced reward rule. The
proof does not itself reveal the reports.

The proof does not show that voters exerted effort. Effort is induced by the
mechanism-design incentive analysis, not cryptographically proven.
