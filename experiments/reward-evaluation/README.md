# Reward Evaluation

This directory contains reproducible data and paper-style figures for the
experimental MACI reward sidecar.

The evaluation shows feasibility and mechanism behavior for the integrated
`N = 8` prototype, plus a fixed-capacity reward-circuit utilization experiment
at `N_max = 64`: a real MACI local run, a reward proof, on-chain reward
finalization, and small parameter studies around the single peer-prediction
reward rule.

## Evaluation Goal

The prototype claim is:

```text
Official MACI can run a private local voting flow, and a separate reward proof
can bind hidden binary reports to a MACI-derived reward state root, verify
fixed-budget lottery peer-prediction payouts, and finalize claimable rewards
on-chain.
```

The experiments support that claim from three angles. First, the Anvil record
shows that official MACI and the reward sidecar run together end to end. Second,
the reward-rule figures separate report-pattern behavior from stake behavior:
report-pattern experiments use equal stakes, while the stake-concentration
figure is the only one that changes stake. Third, the gas figure isolates the
reward-layer on-chain cost.

## Reader Questions

| Reader question | Matching artifact | What it answers |
| --- | --- | --- |
| Does the full system run locally with real MACI? | `data/full_maci_reward_anvil_latest.json` | Shows official MACI deployment, voter signup, encrypted votes, MACI proofs, reward proof, finalization, and one claim on Anvil. |
| How much overhead does the reward sidecar add? | `figures/e2e_overhead.pdf` | Compares MACI proof time, reward proof time, and reward-layer gas in the same Anvil run. |
| Does the single peer-prediction rule behave sensibly across report patterns? | `figures/reward_sensitivity.pdf` and `figures/lottery_confidence.pdf` | Shows how the largest final payout share changes with the reward scale, including a 512-sample confidence run. |
| Does payout preserve the configured total budget? | `figures/budget_allocation.pdf` | Shows one per-voter fixed-budget lottery payout vector for the MACI-derived profile on a log y-axis. |
| How do public stakes affect incentives? | `figures/stake_concentration.pdf` | Increases one voter's stake and compares that voter's average fixed-budget lottery payout with the average of the others. |
| What are the reward-specific gas costs? | `figures/cost_profile.pdf` | Separates root registration, pool funding, proof verification plus finalization, and recipient claim. |
| How much capacity is wasted when a max-size reward circuit is underfilled? | `figures/reward_scaling.pdf` | Uses one `N_max = 64` reward circuit and varies active voters across `8, 16, 32, 64`. |
| What does operation cost look like at larger dispute sizes? | `figures/operating_cost_projection.pdf` | Projects reward-layer operating cost for 10, 100, and 1000 claimants under fixed gas-price scenarios. |
| What public payout exposure does one hidden report have? | `data/exposure_sanity.csv` | Flips one report at a time and counts changed public payout coordinates. |

## Public Transcript Privacy Notes

The paper-level privacy object is the public reward transcript, not a single
recipient's payout. In this prototype the transcript includes the public payout
vector, verifier public inputs, reward finalization transaction data, claimable
balances, and other on-chain reward contract state.

The implementation uses ring peer matching:

```text
peer_i = (i + 1) mod N
```

Changing voter `t`'s hidden report directly affects the peer-agreement test for
voter `t`, and for any voter that uses `t` as its peer. In the ring graph there
is exactly one such predecessor, `(t - 1) mod N`, so the direct peer-graph
exposure is:

```text
D_graph = 2
directly affected coordinates: {t, (t - 1) mod N}
```

The current public payout vector has a larger conservative exposure. The
same-dispute leave-one-out normalizer can change score denominators for other
voters, the fixed-budget allocation normalizes every payout by the same total
allocation score, and the current lottery seed includes `finalRewardStateRoot`.
Because a report flip changes that root, it can also resample lottery draws.
For the integrated `N = 8` prototype, the documented transcript exposure degree
is therefore:

```text
D = 8
```

The exposure sanity CSV confirms this bound for the included profiles: the
maximum observed `changedPayoutCount` is `8`. If a target transcript
distinguishability budget is `eta`, the coordinate-level design target for this
prototype should be read as approximately `eta / 8`. A future low-exposure
variant would need to remove or localize the global normalizer, global
fixed-budget denominator, or root-dependent lottery resampling before claiming
the lower ring-graph value `D_graph = 2`.

## Theory-To-Prototype Mapping

| Term | Meaning in the paper/prototype | Prototype status |
| --- | --- | --- |
| `rho_tau` / `rhoTau` | Maximum lottery allocation scale used before fixed-budget normalization. It is not an independent final payout cap because final payouts are normalized to `B`. | Implemented as a public circuit input and contract public signal. |
| `eta` | Target distinguishability for the full public reward transcript. | Design parameter only; the prototype does not estimate or enforce `eta`. |
| `D` | Maximum number of public payout coordinates affected by one hidden report. | Documented/measured as `D = 8` for the current `N = 8` public payout transcript; direct ring-graph exposure is `D_graph = 2`. |
| `eta / D` | Coordinate-level leakage target when the transcript budget is split over affected payout coordinates. | Design guidance only; not enforced by code. |
| `kappa` | Reward scale that controls how strongly peer agreement affects lottery eligibility. | Implemented as a public input; experiments sweep it. |
| `p_tilde` | Empirical report-frequency normalizer used by the reward rule. | Approximated by a same-dispute leave-one-out, stake-weighted, smoothed plug-in normalizer. |
| `rewardBudget B` | Fixed total budget distributed by the final payout vector. | Implemented as `rewardBudget`; circuit enforces `sum_i payout_i = B`. |
| nonce source | Randomness input for lottery draws. | Experimental. The full MACI sidecar uses MACI vote command salts as nonce material; deterministic experiments use labeled Poseidon-derived nonces. Production randomness is out of scope. |
| public inputs | Values visible to the verifier/contract. | Implemented: `payouts`, `recipients`, `stakes`, `smoothing`, `kappa`, `scale`, `rhoTau`, `disputeId`, `finalStateRoot`, and `rewardBudget`. |
| private inputs | Witness values hidden by the proof. | Implemented: reports, nonces, MACI state indices, voter ids, nonce commitments, Merkle paths, expected-score witnesses, and division remainders. |

## Reward Semantics And Normalization

The reward rule is a fixed-budget lottery. The circuit first samples lottery
winners from nonce-derived randomness, then converts winner indicators into
allocation scores, and finally normalizes all public payouts to the fixed
budget `B`. This is not a contract that independently pays `rhoTau` to every
Bernoulli winner; `rhoTau` affects the pre-normalization allocation score.

The frequency normalizer is same-dispute leave-one-out:

```text
p_tilde_i(1) = (sum_{j != i} stake_j * report_j + smoothing)
               / (sum_{j != i} stake_j + 2 * smoothing)
p_tilde_i(0) = 1 - p_tilde_i(1)
```

This is a practical plug-in normalizer for independent dispute questions, not a
clean estimator of a universal report frequency across disputes. The formal
incentive guarantee should be read conditionally: the chosen `p_tilde` must
remain inside the paper's truthfulness interval `[beta, alpha]`.

Implemented safeguards are intentionally modest. The model and circuit use
smoothing, denominator checks, bounded public input ranges, and the circuit
checks that expected rewards do not exceed `rhoTau`. The prototype does not
clip `p_tilde` into `[beta, alpha]`, does not learn a historical calibration
distribution, and does not implement a production fallback policy.

## Figure Interpretation

`e2e_overhead`

This plot compares the full MACI proof phase with the reward proof phase, then
shows the reward-layer gas operations from the same Anvil run. It is meant to
answer the practical overhead question: the reward proof is small compared with
MACI proving in this local setup, while reward finalization is the largest
reward-layer transaction.

`reward_sensitivity`

This plot shows a final-payout quantity averaged over deterministic lottery
seed samples. The y-axis is the largest single payout share:

```text
max_i P_i / B
```

where `B` is the fixed reward budget.

`kappa` is the reward scale parameter. At `kappa = 0`, the peer-prediction score
is disabled and the budget is split evenly. As `kappa` increases, peer-matching
voters become more likely to win the lottery, so the fixed budget concentrates
on sampled winners.

The no-match profile stays at the equal baseline because no voter can win the
lottery. Consensus can still concentrate in a given draw because everyone is
eligible but only some voters are sampled as winners. Stakes are equal in this
figure, so differences come from reports, reward scale, and lottery sampling
rather than from stake weighting.

`lottery_confidence`

This plot repeats the reward-scale experiment over 512 deterministic lottery
samples. The MACI-derived line includes a 95% confidence interval for the mean
largest-payout share. The percentile data is also kept in
`lottery_confidence.csv`, but the figure uses the mean confidence interval to
avoid making a single lottery draw look more stable than it is.

`budget_allocation`

This is the easiest plot to read as "who gets paid in this lottery draw." `P_i`
is the final payout for voter `i`, and the bars sum exactly to the configured
reward budget.

In the MACI-derived example, reports are:

```text
voter:  0 1 2 3 4 5 6 7
report: 1 0 1 1 0 0 1 0
peer:   1 2 3 4 5 6 7 0
match:  no no yes no yes no no no
```

Only voter 2 and voter 4 match their assigned peer, so they are eligible for a
large lottery-backed allocation. In the plotted seed, both voters win and split
almost all of the fixed budget. The other voters receive only the small baseline
payout. The y-axis is logarithmic because winner payouts are roughly three
orders of magnitude larger than baseline payouts.

`stake_concentration`

This plot changes voter 2's public stake while keeping the reports fixed and
averaging over deterministic lottery seeds. Since voter 2 has a peer-agreement
signal, increasing voter 2's stake increases voter 2's expected share of the
fixed reward budget and reduces the average share left for the others.

`cost_profile`

This plot shows reward-layer gas only. `Register root` stores the final reward
state root and MACI tally status. `Fund pool` deposits the reward budget.
`Verify + finalize` verifies the Groth16 reward proof and records claimable
balances, so it is the largest operation. `Claim` withdraws one recipient's
already-finalized payout.

`reward_scaling`

This plot uses one generated `N_max = 64` reward circuit, not the integrated
`N = 8` contract, and varies the number of active voters. Inactive slots are
zero-stake padding leaves and receive no baseline payout. The plot shows that
total proof time stays close to the fixed-capacity cost, while per-active voter
time improves as utilization increases. The proving key setup time is stored in
the CSV but omitted from the figure because setup is per circuit, not per
dispute.

`operating_cost_projection`

This plot projects reward-layer operation cost from measured gas. It excludes
deployment and uses fixed scenario prices: 20 gwei on L1, 0.1 gwei for an
Arbitrum execution-only row, and ETH at `$3,000`. It is not a live fee quote;
it is a scale-of-cost comparison.

| Claimants | Ethereum L1, 20 gwei | Arbitrum execution, 0.1 gwei |
| ---: | ---: | ---: |
| 10 | `$69.81` | `$0.35` |
| 100 | `$354.31` | `$1.77` |
| 1000 | `$3,199.24` | `$16.00` |

The table assumes one reward finalization and one claim per recipient.

## Data Files

- `parameter_sweep.csv`: wider parameter sweep over report profiles, smoothing,
  scale, reward budget, and stake multiplier.
- `reward_sensitivity.csv`: reduced data used by the reward-scale sensitivity
  figure, including final payout-share metrics and raw score diagnostics.
- `lottery_confidence.csv`: 512-sample lottery run with mean confidence
  intervals and percentile summaries.
- `exposure_sanity.csv`: one-report-flip sanity check for public payout
  coordinate exposure.
- `budget_allocation.csv`: fixed-budget payout vector for the MACI-derived
  report profile.
- `stake_concentration.csv`: dominant-stake sweep.
- `e2e_overhead.csv`: MACI/reward proof time and reward gas from the latest full
  MACI + reward Anvil run.
- `operating_cost_projection.csv`: projected reward-layer operating cost for
  10, 100, and 1000 claimants under fixed gas-price scenarios.
- `reward_scaling.csv`: fixed-capacity `N_max = 64` utilization data for
  `8, 16, 32, 64` active voters.
- `reward_utilization.csv`: same data as `reward_scaling.csv`, kept under the
  explicit utilization name for analysis scripts.
- `gas_breakdown.csv`: reward-layer gas from the full MACI + reward Anvil run.
- `reward_only_gas_breakdown.csv`: reward-only Anvil gas for comparison.
- `anvil_reward_e2e_latest.json`: reward-only Anvil output.
- `full_maci_reward_anvil_latest.json`: full MACI + reward Anvil output.
- `proof_shape.csv`: reward circuit public/private input and constraint counts.

## Regeneration

From the repository root:

```bash
cd poc
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
npm run experiments:reward-data
npm run experiments:reward-scaling
npm run experiments:reward-plots
```

The plotting script writes both PNG previews and vector PDF figures under
`figures/`.

## Scope Boundaries

- The integrated MACI + reward flow is fixed at `N = 8`; reward-circuit
  utilization data is standalone with `N_max = 64`.
- MACI command salts remain part of the sidecar binding; a dedicated MACI reward
  field would require a deeper MACI circuit change.
- Production audit, Sybil resistance, live fee estimation, and user-effort
  validation are separate work.
