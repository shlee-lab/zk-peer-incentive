# Reward Circuit

`reward_check.circom` is the v1 lottery reward circuit for the relation in
`../zk_relation.md`.

It verifies lottery payouts for hidden binary reports and private nonces using:

- smoothed stake-weighted leave-one-out frequency;
- inverse-frequency peer agreement;
- ring peer matching, `peer(i) = i+1 mod N`;
- integer floor payouts via quotient/remainder constraints.
- Poseidon seed `H(nonces..., disputeId, stateRoot)`;
- per-voter draw `H(seed, i)` with low 32 bits used as the lottery draw.

## Current Scope

This is not a full MACI integration. v1 does not prove that the private reports
or nonces are included in a final vote state. It only proves that, given hidden
reports/nonces and public context, the public lottery payouts were computed
according to the reward rule.

## Install Tools

Install Circom and snarkjs using their official installation instructions. A
typical local setup is:

```bash
npm install -g snarkjs
```

Circom itself is usually installed from the Circom release binaries or built
from source.

## Compile

From `poc/`:

```bash
circom circuits/reward_check.circom --r1cs --wasm --sym -o artifacts/v1
```

## Groth16 Dev Ceremony

For local testing only:

```bash
npx snarkjs powersoftau new bn128 14 artifacts/v1/pot14_0000.ptau
npx snarkjs powersoftau contribute artifacts/v1/pot14_0000.ptau artifacts/v1/pot14_0001.ptau --name="v1 dev contribution" -e="zk-peer-incentive-v1-pot"
npx snarkjs powersoftau prepare phase2 artifacts/v1/pot14_0001.ptau artifacts/v1/pot14_final.ptau
npx snarkjs groth16 setup artifacts/v1/reward_check.r1cs artifacts/v1/pot14_final.ptau artifacts/v1/reward_check_0000.zkey
npx snarkjs zkey contribute artifacts/v1/reward_check_0000.zkey artifacts/v1/reward_check_final.zkey --name="v1 dev zkey" -e="zk-peer-incentive-v1-zkey"
npx snarkjs zkey export verificationkey artifacts/v1/reward_check_final.zkey artifacts/v1/verification_key.json
```

## Solidity Verifier

```bash
npx snarkjs zkey export solidityverifier artifacts/v1/reward_check_final.zkey contracts/RewardGroth16Verifier.sol
```

The generated verifier is wired into `RewardPool` through
`contracts/RewardVerifierAdapter.sol`.

## Known Next Step

v2 should bind the reports/nonces used by this circuit to a MACI-like final
state root with Merkle inclusion proofs.
