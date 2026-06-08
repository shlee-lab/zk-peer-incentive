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

The experiments support that claim with five kinds of evidence:

- end-to-end execution evidence;
- behavior of the same reward rule under different report profiles;
- fixed-budget allocation behavior;
- stake-weighting behavior;
- reward-layer on-chain cost.

## Reader Questions

| Reader question | Matching artifact | What it answers |
| --- | --- | --- |
| Does the full system run locally with real MACI? | `data/full_maci_reward_anvil_latest.json` | Shows official MACI deployment, voter signup, encrypted votes, MACI proofs, reward proof, finalization, and one claim on Anvil. |
| Does the single peer-prediction rule behave sensibly across report patterns? | `figures/reward_sensitivity.pdf` | Runs the same rule under MACI-derived, one-sided, consensus, and alternating binary reports as the incentive scale changes. |
| Does payout preserve the configured total budget? | `figures/budget_allocation.pdf` | Shows per-voter payouts for the MACI-derived profile and the exact fixed-budget total. |
| How do public stakes affect incentives? | `figures/stake_concentration.pdf` | Increases one voter's stake and compares that voter's fixed-budget payout with the average of the others. |
| What are the reward-specific gas costs? | `figures/cost_profile.pdf` | Separates root registration, pool funding, proof verification plus finalization, and recipient claim. |

## Figure Interpretation

`reward_sensitivity`

- `T_i` is the unnormalized peer-prediction score before budget normalization.
- `kappa` is the incentive scale parameter.
- This is a calibration and implementation-check plot for the proposed
  peer-prediction rule under representative report profiles and scale choices.

`budget_allocation`

- `P_i` is the fixed-budget payout for voter `i`.
- `sum_i P_i` equals the configured reward budget.
- Bars are colored by binary report value for the MACI-derived report profile.

`stake_concentration`

- The dominant voter keeps the same report but receives a larger public stake.
- The plot checks that the stake-weighted rule shifts fixed-budget payout share
  in the expected direction.

`cost_profile`

- `Register root` records the final reward state root and MACI tally status.
- `Fund pool` deposits reward funds.
- `Verify + finalize` verifies the Groth16 reward proof and records claimable
  balances.
- `Claim` withdraws one recipient's already-finalized payout.

## Data Files

- `parameter_sweep.csv`: wider parameter sweep over report profiles, smoothing,
  scale, reward budget, and stake multiplier.
- `reward_sensitivity.csv`: reduced data used by the reward-rule behavior
  figure.
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
