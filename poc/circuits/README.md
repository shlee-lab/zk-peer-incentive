# Reward Circuit

`reward_check.circom` implements the reward sidecar relation described in
`../zk_relation.md`.

It proves that hidden binary reports are included in a registered reward state
root and that each public payout follows a coordinate-wise Bernoulli lottery:

```text
payout_i = rhoTau if low32(Poseidon(seed, i)) < q_i * 2^32
payout_i = 0 otherwise
```

The circuit supports two modes:

```text
lotteryMode = 0: q_i = x_i / rhoTau
lotteryMode = 1: q_i = psi + (1 - 2 psi) * x_i / rhoTau
```

Baseline mode requires `psiScaled = 0`. Floor-adjusted mode requires
`0 < psi < 1/2` and the circuit enforces `q_i in [psi, 1 - psi]`. Public
payouts must be binary values in `{0, rhoTau}`.

The circuit checks:

- smoothed stake-weighted leave-one-out frequency;
- inverse-frequency peer agreement;
- ring peer matching, `peer(i) = i+1 mod N`;
- Poseidon nonce commitments `H(nonce_i, 0)`;
- Poseidon reward sidecar leaves
  `H(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i, recipient_i)`;
- fixed-position Merkle openings for all 8 voters to `finalStateRoot`;
- public recipient addresses bound to the sidecar leaves;
- external `randomSeed` mixed with `disputeId` and `finalStateRoot`;
- `lotteryMode`, `psiScaled`, threshold arithmetic, and draw comparison inside
  the circuit;
- expected-payout cap against `rewardBudget`;
- range checks for public parameters and arithmetic witnesses.

The contract layer is responsible for fixing `randomSeed` only after
`finalStateRoot` registration. The local PoC uses commit-reveal.

## Compile

From `poc/`:

```bash
circom circuits/reward_check.circom --r1cs --wasm --sym -o artifacts/v2
```

## Groth16 Dev Ceremony

For local testing only:

```bash
npx snarkjs powersoftau new bn128 15 artifacts/v2/pot15_0000.ptau
npx snarkjs powersoftau contribute artifacts/v2/pot15_0000.ptau artifacts/v2/pot15_0001.ptau --name="v2 dev contribution" -e="zk-peer-incentive-v2-pot"
npx snarkjs powersoftau prepare phase2 artifacts/v2/pot15_0001.ptau artifacts/v2/pot15_final.ptau
npx snarkjs groth16 setup artifacts/v2/reward_check.r1cs artifacts/v2/pot15_final.ptau artifacts/v2/reward_check_0000.zkey
npx snarkjs zkey contribute artifacts/v2/reward_check_0000.zkey artifacts/v2/reward_check_final.zkey --name="v2 dev zkey" -e="zk-peer-incentive-v2-zkey"
npx snarkjs zkey export verificationkey artifacts/v2/reward_check_final.zkey artifacts/v2/verification_key.json
```

## Solidity Verifier

```bash
npx snarkjs zkey export solidityverifier artifacts/v2/reward_check_final.zkey contracts/RewardGroth16Verifier.sol
```

The generated verifier is wired into the generic reward pool interface through
`contracts/RewardVerifierAdapter.sol`.

## Public Signal Order

The current public input vector has 34 values:

```text
payouts[0..7]
recipients[8..15]
stakes[16..23]
smoothing[24]
kappa[25]
scale[26]
rhoTau[27]
disputeId[28]
finalStateRoot[29]
rewardBudget[30]
lotteryMode[31]
psiScaled[32]
randomSeed[33]
```

Current measured shape:

```text
constraints: 30,164
public inputs: 34
private inputs: 112
```

## Current Scope

This is a reward sidecar relation for an unmodified MACI flow. MACI message
processing and tally correctness are handled by the pinned official MACI
baseline. The private `nonces[i]` values are MACI command-salt-derived material
in the full MACI experiment.
