# Reward-Layer Scaling Results

This directory contains the reward-layer-only scaling benchmark used for the
paper figure. It is separate from the 8-voter full MACI plus reward Anvil run.

The interpretation is:

```text
N = 8 full MACI + reward run:
  end-to-end feasibility evidence

N = 8, 16, 32, 64 reward-layer benchmark:
  reward circuit and reward contract scaling evidence
```

The larger-N rows do not measure full MACI proof generation, MACI message
processing, or MACI contract costs. They use deterministic fixture states that
stand in for MACI-derived final reward states.

## Reproduce

From the repository root:

```bash
cd poc
. .venv/bin/activate
npm run benchmark:reward-layer-scaling
```

The checked-in run used:

```bash
cd poc
. .venv/bin/activate
REWARD_LAYER_SCALING_N=8,16,32,64 npm run benchmark:reward-layer-scaling
```

The default reporter counts are:

```text
N = 8, 16, 32, 64
```

Useful knobs:

```bash
REWARD_LAYER_SCALING_N=8,16,32,64 npm run benchmark:reward-layer-scaling
REWARD_LAYER_SCALING_PTAU=/tmp/maci-official/zkeys/powersOfTau28_hez_final_19.ptau npm run benchmark:reward-layer-scaling
```

`N = 128` is intentionally not part of the default run. It may require a larger
powers-of-tau file and a longer local setup/proving time.

## Measurement Setup

The checked-in numbers are single-run measurements, not means or medians.
`REWARD_LAYER_SCALING_REPETITIONS` is recorded as `1`.

Machine recorded by the benchmark:

```text
OS: Linux 6.6.87.2-microsoft-standard-WSL2 x64
CPU: Intel(R) Core(TM) Ultra 7 258V
logical cores: 8
memory: 16.5 GB
Node: v24.15.0
```

For each `N`, the script:

```text
generates an N-specific reward circuit
compiles the circuit
runs Groth16 setup with the configured ptau
generates a witness
generates and verifies a proof with snarkjs
exports an N-specific Solidity verifier
deploys the verifier and reward benchmark contracts on local Anvil
registers a reward root
verifies/finalizes rewards
claims one positive payout
```

Gas is measured on local Anvil. The script starts Anvil with:

```text
accounts: 200
gas limit: 30,000,000
code size limit: 1,000,000 bytes
```

The enlarged code-size limit is used because generated Solidity verifiers grow
with the number of public inputs. Deployment gas is recorded in JSON but is not
included in the main reward-layer operating-gas figure.

Circuits are compiled once per `N` in the benchmark run. The benchmark records
single witness/proof/verification timings per `N`.

## Outputs

```text
results/scaling_reward_layer.csv
results/scaling_reward_layer.json
results/figures/reward_layer_scaling_summary.pdf
results/figures/reward_layer_scaling_summary.png
results/figures/constraints_vs_n.pdf
results/figures/proving_time_vs_n.pdf
results/figures/reward_layer_gas_vs_n.pdf
results/figures/total_claim_gas_vs_n.pdf
results/figures/transcript_size_vs_n.pdf
```

The preferred paper figure is `reward_layer_scaling_summary.pdf`, with:

```text
A. reward circuit constraints vs N
B. reward proof time vs N
C. reward-layer gas vs N
```

## Current Snapshot

| N | Constraints | Proof time | Verifier gas | Finalize gas | Reward-layer gas, no claims |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 8 | `30,164` | `2.529 s` | `461,786` | `585,409` | `839,760` |
| 16 | `63,388` | `4.053 s` | `632,056` | `809,768` | `1,064,119` |
| 32 | `133,676` | `8.377 s` | `972,873` | `1,358,747` | `1,613,098` |
| 64 | `281,932` | `19.709 s` | `1,654,342` | `2,316,575` | `2,570,914` |

## Columns

The CSV records:

```text
N
rewardCircuitConstraints
publicInputsCount
privateInputsCount
witnessGenerationTimeMs
proofGenerationTimeMs
proofVerificationTimeMs
solidityVerifierGas
rewardRootRegistrationGas
rewardFinalizationGas
totalRewardLayerGasExcludingIndividualClaims
oneRecipientClaimGas
totalClaimGasIfAllNRecipientsClaim
rewardTranscriptSizeBytes
payoutVectorLength
peerGraphDegree
sampledPeersPerReporter
payoutMode
psi
psiScaled
rewardCapRhoTau
effectiveRewardCapacityRhoTauEff
```

`totalRewardLayerGasExcludingIndividualClaims` includes seed commit, reward
root registration, seed reveal, pool funding, and reward finalization. It
excludes deployment and individual claims.

`oneRecipientClaimGas` is measured on one positive-payout recipient.
`totalClaimGasIfAllNRecipientsClaim` is a linear extrapolation for the case
where every recipient has a positive claim. In a Bernoulli lottery run, some
coordinates may have zero payout and therefore no claim transaction.
