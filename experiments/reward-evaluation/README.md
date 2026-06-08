# Reward Evaluation

This directory contains reproducible data and paper-style figures for the
experimental MACI reward sidecar.

The evaluation is intentionally scoped. It shows feasibility and basic
mechanism behavior for a fixed `N = 8` prototype. It does not claim production
security, protocol optimality, user-study validation, or large-scale
performance.

## Evaluation Goal

The prototype claim is:

```text
Official MACI can run a private local voting flow, and a separate reward proof
can bind hidden binary reports to a MACI-derived reward state root, verify
peer-prediction lottery payouts, and finalize claimable rewards on-chain.
```

The experiments are designed to support that claim with five kinds of evidence:

- end-to-end execution evidence;
- reward-rule behavior under different report profiles;
- lottery payout behavior relative to the expected reward;
- stake-sensitivity behavior;
- reward-layer on-chain cost.

## Reader Questions

| Reader question | Matching artifact | What it answers |
| --- | --- | --- |
| Does the full system run locally with real MACI? | `data/full_maci_reward_anvil_latest.json` | Shows official MACI deployment, voter signup, encrypted votes, MACI proofs, reward proof, finalization, and one claim on Anvil. |
| Does the reward rule behave sensibly across report patterns? | `figures/reward_sensitivity.pdf` | Compares total expected reward under MACI-derived, one-sided, consensus, and alternating binary reports as the incentive scale changes. |
| Does the lottery preserve expected payout in aggregate? | `figures/lottery_unbiasedness.pdf` | Samples deterministic command-salt vectors and plots the cumulative realized mean against the theoretical expected reward. |
| How do public stakes affect incentives? | `figures/stake_concentration.pdf` | Increases one voter's stake and compares that voter's expected reward with the average of the others. |
| What are the reward-specific gas costs? | `figures/cost_profile.pdf` | Separates root registration, pool funding, proof verification plus finalization, and winner claim. |

## Figure Interpretation

`reward_sensitivity`

- `T_i` is the expected peer-prediction reward before lottery sampling.
- `kappa` is the incentive scale parameter.
- The plot checks qualitative mechanism behavior, not privacy or security.

`lottery_unbiasedness`

- `P_i` is the realized lottery payout.
- `bar(P)_t` is the cumulative mean total payout over `t` sampled salt vectors.
- The dashed line is the theoretical total expected reward `sum_i T_i`.
- The sampled salt vectors evaluate the lottery reduction statistically; they
  are not a production randomness-beacon experiment.

`stake_concentration`

- The dominant voter keeps the same report but receives a larger public stake.
- The plot checks that the stake-weighted rule scales expected reward in the
  expected direction.

`cost_profile`

- `Register root` records the final reward state root and MACI tally status.
- `Fund pool` deposits reward funds.
- `Verify + finalize` verifies the Groth16 reward proof and records claimable
  balances.
- `Claim` withdraws one winner's already-finalized payout.

## Data Files

- `parameter_sweep.csv`: wider parameter sweep over report profiles, smoothing,
  scale, jackpot amount, and stake multiplier.
- `reward_sensitivity.csv`: reduced data used by the sensitivity figure.
- `lottery_trials.csv`: repeated lottery realizations for the MACI-derived
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

## What This Does Not Show

- It does not benchmark large `N`.
- It does not modify official MACI circuits to add a new reward-nonce field.
- It does not prove that users performed costly human effort.
- It does not solve Sybil resistance.
- It does not audit the sidecar mapping from MACI state index to recipient
  address.
- It does not replace MACI's privacy or correctness assumptions.
