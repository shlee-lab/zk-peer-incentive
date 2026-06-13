# Reward Evaluation

This directory contains the data and figures used to describe the experimental
MACI reward sidecar. The current implementation is a coordinate-wise Bernoulli
lottery reward rule bound to a MACI-derived reward state root. The older
exact-budget allocation mode is retained only as a comparison baseline.

The evaluation supports a narrow claim: official MACI can run a local encrypted
voting flow, and a separate Groth16 reward proof can bind hidden binary reports
to a reward state root, verify lottery payouts, and finalize claimable rewards
on Anvil.

## Reader Questions

| Reader question | Matching artifact | What it answers |
| --- | --- | --- |
| Does the full system run locally with real MACI? | `data/full_maci_reward_anvil_latest.json` | Official MACI deployment, signup, encrypted votes, MACI proofs, reward proof, finalization, and one claim. |
| How much overhead does the reward sidecar add? | `figures/e2e_overhead.pdf` | MACI proof time, reward proof time, and reward-layer gas from one Anvil run. |
| Does the reward rule react to report patterns? | `figures/reward_sensitivity.pdf`, `figures/lottery_confidence.pdf` | How lottery concentration changes as `kappa` changes. |
| How much can one hidden report move public probabilities? | `data/exposure_probability_sanity.csv` | Per-coordinate changes in `q_j` after flipping one report. |
| How visible is one report across repeated rounds? | `figures/attack_simulation.pdf` | Likelihood-ratio distinguishing advantage for two worlds differing in one report. |
| What is the reward-layer gas cost? | `figures/cost_profile.pdf` | Seed commit, root registration, seed reveal, pool funding, proof finalization, and claim gas. |
| What happens with a larger max-size reward circuit? | `figures/reward_scaling.pdf` | Standalone `N_max = 64` capacity experiment. |

## Theory-To-Prototype Mapping

| Term | Meaning | Prototype status |
| --- | --- | --- |
| `rho_tau` / `rhoTau` | Per-coordinate payout amount and reward cap scale. A winner receives exactly `rhoTau`; a loser receives `0`. | Implemented as a public circuit input and contract public signal. |
| `gamma` / `gammaScaled` | Lower and upper lottery-probability clamp. The circuit enforces `q_i in [gamma, 1-gamma]`. | Implemented as public `gammaScaled = floor(gamma * 2^32)`. Current integrated run uses `gamma = 0.05`. |
| `eta` | Target distinguishability for the whole public reward transcript. | Design parameter. The prototype measures attack advantage but does not enforce a chosen `eta`. |
| `D` | Number of public payout coordinates affected by one hidden report. | Direct ring exposure is `D_graph = 2`; measured probability exposure includes smaller second-order effects across more coordinates. |
| `eta / D` | Coordinate-level leakage target when the transcript budget is split across affected coordinates. | Design guidance only. The data reports actual `q_j` movement so the paper can choose a conservative correction. |
| `kappa` | Reward scale. It controls how strongly peer agreement increases `x_i`, and therefore `q_i`. | Implemented as a public input and swept in experiments. |
| `p_tilde` | Empirical frequency normalizer used by the inverse-frequency score. | Implemented as same-dispute leave-one-out, stake-weighted, smoothed plug-in normalizer. |
| `rewardBudget B` | Expected-payout cap used by the circuit. It is not an exact final payout sum. | Implemented: circuit checks expected payout mass is at most `B`; contract funds maximum exposure separately. |
| nonce source | Private material bound into the reward sidecar leaf. | Experimental. Full MACI flow derives it from MACI vote command salts. |
| lottery seed source | Public randomness used for Bernoulli draws. | Experimental commit-reveal: seed is committed before root registration and revealed after root registration. |
| public inputs | Values visible to verifier and contract. | `payouts`, `recipients`, `stakes`, `smoothing`, `kappa`, `scale`, `rhoTau`, `disputeId`, `finalStateRoot`, `rewardBudget`, `gammaScaled`, `randomSeed`. |
| private inputs | Witness values hidden by the proof. | reports, nonces, MACI state indices, voter ids, nonce commitments, Merkle paths, expected scores, raw thresholds, and division remainders. |

## Reward Semantics

The active reward rule is independent per coordinate:

```text
x_i         = smoothed inverse-frequency peer-agreement score
q_i         = clamp(x_i / rhoTau, gamma, 1 - gamma)
u_i         = low32(Poseidon(seed, i))
payout_i    = rhoTau if u_i < q_i * 2^32, otherwise 0
```

The proof enforces the clamp and threshold comparison inside the circuit. The
public payout vector must therefore contain only `0` and `rhoTau`.

The per-coordinate draws are separated as `Poseidon(seed, i)`; the independence
claim here is computational pseudorandomness, not statistical independence.

The total payout is random. The integrated run funds the pool for maximum
exposure:

```text
N * rhoTau = 8 * 3,000,000 = 24,000,000
```

The expected-payout budget is a cap on probability mass. With
`gamma = 0.05`, the gamma floor alone contributes:

```text
N * gamma * rhoTau = 8 * 0.05 * 3,000,000 = 1,200,000
```

The fixed-budget data files and figure remain because they are useful as a
baseline for comparing exact-budget allocation with low-exposure Bernoulli
lottery payouts. They should not be cited as the current contract behavior.

## Public Transcript Exposure

The paper-level privacy object is the full public reward transcript: payout
vector, verifier public inputs, finalization transaction data, claimable
balances, and on-chain reward state.

The peer graph is a ring:

```text
peer_i = (i + 1) mod N
```

Changing voter `t` directly affects voter `t`'s own agreement test and the
predecessor `(t - 1) mod N` that uses `t` as a peer. That first-order graph
exposure is:

```text
D_graph = 2
```

The same-dispute leave-one-out normalizer also changes other voters'
probabilities. The script `poc/scripts/run_reward_experiments.js` flips each
report and records the per-coordinate change in `q_j`. For the included
profiles, the largest observed values are:

| gamma | Max direct `|Delta q|` | Max secondary `|Delta q|` |
| ---: | ---: | ---: |
| 0.02 | `0.96000000` | `0.20580666` |
| 0.05 | `0.90000000` | `0.18882766` |
| 0.10 | `0.80000000` | `0.18882766` |

So the ring graph has bounded first-order exposure, but the current
same-dispute normalizer creates measurable second-order transcript movement.
The CSV gives the paper a data-backed alternative to simply treating all
`N = 8` coordinates as equally affected.

## Normalizer Scope

The implementation uses same-dispute leave-one-out:

```text
p_tilde_i(1) = (sum_{j != i} stake_j * report_j + smoothing)
               / (sum_{j != i} stake_j + 2 * smoothing)
p_tilde_i(0) = 1 - p_tilde_i(1)
```

This is a practical plug-in normalizer for independent dispute questions. It is
not a clean estimator of a universal distribution across disputes. The formal
incentive guarantee should be read conditionally: the chosen `p_tilde` must
stay inside the truthfulness interval `[beta, alpha]`.

Implemented safeguards are smoothing, denominator checks, public-input range
checks, gamma clamp checks, and an expected-payout cap. The prototype does not
learn historical calibration, clip `p_tilde` into `[beta, alpha]`, or implement
a production fallback policy.

## Figure Notes

`e2e_overhead` compares the MACI proof phase, reward proof phase, and reward gas
operations from the same Anvil run. `Verify + finalize` is the largest reward
operation because it verifies the Groth16 proof and records claimable payouts.

`reward_sensitivity` sweeps `kappa`. Larger `kappa` means peer agreement has
more influence on the lottery threshold. Equal stakes are used here, so changes
come from reports, reward scale, and lottery sampling rather than stake
weighting.

`lottery_confidence` repeats the sensitivity run over 512 deterministic lottery
samples and plots a confidence interval for the mean largest-payout share.

`attack_simulation` samples two worlds that differ only in one target report.
For each `k = 1..50`, it draws `M = 10000` transcripts per world and evaluates
the optimal likelihood-ratio classifier. The plotted theory curve is the
clipped advantage expression
`eta * sqrt(k / (2 gamma (1 - gamma))) / 2`. With the current high-signal
parameters, both empirical and clipped theory curves reach the 50% ceiling.

`budget_allocation` is the legacy exact-budget baseline. It is kept to compare
exact-budget and Bernoulli semantics, not to describe the current
`IntegratedRewardPool` payout rule.

`reward_scaling` is standalone. It compiles a max-size `N_max = 64` reward
circuit and varies active inputs. Because the Bernoulli rule has a gamma floor,
capacity planning must consider the max-size coordinate count, not only the
number of nonzero-stake voters.

## Current Measurement Snapshot

The latest synchronized full MACI + reward Anvil run was generated from the
working tree based on commit `e8cf1a4` and produced:

```text
MACI proof phase: 124.084 s
Reward proof phase: 4.618 s
Reward circuit: 26,080 constraints, 33 public inputs, 96 private inputs
Commit seed: 49,899 gas
Register root: 98,837 gas
Reveal seed: 58,248 gas
Fund pool: 47,396 gas
Verify + finalize: 557,212 gas
Claim: 30,707 gas
```

The public payout vector in that run was:

```text
[0, 0, 3000000, 0, 0, 0, 0, 0]
```

## Data Files

| File | Contents |
| --- | --- |
| `full_maci_reward_anvil_latest.json` | Full MACI plus reward Anvil run. |
| `anvil_reward_e2e_latest.json` | Reward-only Anvil run. |
| `proof_shape.csv` | Reward circuit constraint and input counts. |
| `gas_breakdown.csv` | Reward gas from full MACI plus reward run. |
| `reward_only_gas_breakdown.csv` | Reward-only gas comparison. |
| `e2e_overhead.csv` | Proof time and reward gas used by the overhead figure. |
| `exposure_probability_sanity.csv` | Per-coordinate `q_j` movement after one report flip. |
| `attack_simulation.csv` | Repeated-round transcript distinguishing simulation. |
| `reward_sensitivity.csv` | Reward-scale sweep. |
| `lottery_confidence.csv` | 512-sample lottery confidence data. |
| `budget_allocation.csv` | Legacy exact-budget baseline payout vector. |
| `stake_concentration.csv` | Public stake concentration sweep. |
| `operating_cost_projection.csv` | Reward-layer operating cost scenarios. |
| `reward_scaling.csv` | Standalone `N_max = 64` capacity experiment. |

## Regeneration

From the repository root:

```bash
cd poc
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
npm run experiments:reward-data
npm run experiments:attack-simulation
npm run experiments:reward-scaling
npm run experiments:reward-plots
```

`npm run experiments:reward` runs the same full sequence in one command.

## Scope

The integrated run is fixed at `N = 8`. The `N_max = 64` data is a standalone
capacity experiment, not a full MACI deployment at 64 voters. The prototype is
not audited. Sybil policy, production randomness, registration policy, live fee
quotes, and validation of actual human effort are outside this repository.
