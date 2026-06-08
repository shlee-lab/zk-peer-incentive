# Reward Evaluation

This directory contains reproducible data and paper-style figures for the
experimental MACI reward sidecar.

The evaluation shows feasibility and mechanism behavior for the fixed `N = 8`
prototype: a real MACI local run, a reward proof, on-chain reward finalization,
and small parameter studies around the single peer-prediction reward rule.

## Evaluation Goal

The prototype claim is:

```text
Official MACI can run a private local voting flow, and a separate reward proof
can bind hidden binary reports to a MACI-derived reward state root, verify
fixed-budget peer-prediction payouts, and finalize claimable rewards on-chain.
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
| Does the single peer-prediction rule behave sensibly across report patterns? | `figures/reward_sensitivity.pdf` | Shows how the largest final payout share changes with the reward scale, with stakes fixed. |
| Does payout preserve the configured total budget? | `figures/budget_allocation.pdf` | Shows per-voter payouts for the MACI-derived profile on a log y-axis, so both peer-match payouts and baseline payouts are visible. |
| How do public stakes affect incentives? | `figures/stake_concentration.pdf` | Increases one voter's stake and compares that voter's fixed-budget payout with the average of the others. |
| What are the reward-specific gas costs? | `figures/cost_profile.pdf` | Separates root registration, pool funding, proof verification plus finalization, and recipient claim. |

## Figure Interpretation

`reward_sensitivity`

This plot shows a final-payout quantity, not an internal score. The y-axis is
the largest single payout share:

```text
max_i P_i / B
```

where `B` is the fixed reward budget.

`kappa` is the reward scale parameter. At `kappa = 0`, the peer-prediction score
is disabled and the budget is split evenly. As `kappa` increases, report
profiles with only a few peer matches concentrate more of the fixed budget on
those matching voters.

The MACI-derived profile approaches a 50% largest-payout share because two
voters match their peers and split almost all of the budget. The one-sided
profile approaches about one-sixth because six voters match. Consensus and
alternating are shown as equal-split cases: consensus gives everyone the same
peer-match status, while alternating gives no one a peer match. Stakes are equal
in this figure, so differences come from reports rather than from stake
weighting.

`budget_allocation`

This is the easiest plot to read as "who gets paid." `P_i` is the final payout
for voter `i`, and the bars sum exactly to the configured reward budget.

In the MACI-derived example, reports are:

```text
voter:  0 1 2 3 4 5 6 7
report: 1 0 1 1 0 0 1 0
peer:   1 2 3 4 5 6 7 0
match:  no no yes no yes no no no
```

Only voter 2 and voter 4 match their assigned peer, so they receive almost all
of the budget. The other voters receive only the small baseline payout. The
y-axis is logarithmic because the peer-match payouts are roughly three orders of
magnitude larger than the baseline payouts.

`stake_concentration`

This plot changes voter 2's public stake while keeping the reports fixed. Since
voter 2 has a peer-agreement signal, increasing voter 2's stake increases voter
2's share of the fixed reward budget and reduces the average share left for the
others.

`cost_profile`

This plot shows reward-layer gas only. `Register root` stores the final reward
state root and MACI tally status. `Fund pool` deposits the reward budget.
`Verify + finalize` verifies the Groth16 reward proof and records claimable
balances, so it is the largest operation. `Claim` withdraws one recipient's
already-finalized payout.

## Data Files

- `parameter_sweep.csv`: wider parameter sweep over report profiles, smoothing,
  scale, reward budget, and stake multiplier.
- `reward_sensitivity.csv`: reduced data used by the reward-scale sensitivity
  figure, including final payout-share metrics and raw score diagnostics.
- `budget_allocation.csv`: fixed-budget payout vector for the MACI-derived
  report profile.
- `stake_concentration.csv`: dominant-stake sweep.
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
npm run experiments:reward
```

The plotting script writes both PNG previews and vector PDF figures under
`figures/`.

## Scope Boundaries

- The data is for a fixed-size `N = 8`, binary-report prototype.
- MACI command salts remain part of the sidecar binding; a dedicated MACI reward
  field would require a deeper MACI circuit change.
- Production audit, large-scale benchmarking, Sybil resistance, and user-effort
  validation are separate work.
