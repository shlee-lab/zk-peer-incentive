# Reward Circuit

`reward_check.circom` is the v2 lottery reward circuit for the relation in
`../zk_relation.md`.

It verifies lottery payouts for hidden binary reports and private nonces using:

- smoothed stake-weighted leave-one-out frequency;
- inverse-frequency peer agreement;
- ring peer matching, `peer(i) = i+1 mod N`;
- integer floor payouts via quotient/remainder constraints.
- Poseidon seed `H(nonces..., disputeId, stateRoot)`;
- per-voter draw `H(seed, i)` with low 32 bits used as the lottery draw.
- Poseidon final-state leaves
  `H(voterId_i, report_i, nonce_i, stake_i)`;
- fixed-position Merkle openings for all 8 voters to `finalStateRoot`.

## Current Scope

This is not a full MACI integration. v2 proves that the private reports and
nonces used by the reward computation are included in a MACI-like final state
root. It does not prove MACI message processing, coordinator behavior, or tally
correctness.

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

The generated verifier is wired into `RewardPool` through
`contracts/RewardVerifierAdapter.sol`.

## Known Next Step

v3 should add an integrated final-state registry/reward-pool flow on Anvil.
