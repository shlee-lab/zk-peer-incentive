# Reward Circuit

`reward_check.circom` is a minimal circuit draft for the reward relation in
`../zk_relation.md`.

It verifies fixed-point payouts for hidden binary reports using:

- smoothed stake-weighted leave-one-out frequency;
- inverse-frequency peer agreement;
- ring peer matching, `peer(i) = i+1 mod N`;
- integer floor payouts via quotient/remainder constraints.

## Current Scope

This is not a full MACI integration. It does not prove that the private reports
are consistent with encrypted MACI messages. It only proves that, given hidden
reports, the public payouts were computed according to the reward rule.

## Install Tools

Install Circom and snarkjs using their official installation instructions. A
typical local setup is:

```bash
npm install -g snarkjs
```

Circom itself is usually installed from the Circom release binaries or built
from source.

## Compile

```bash
circom reward_check.circom --r1cs --wasm --sym --c
```

## Groth16 Dev Ceremony

For local testing only:

```bash
snarkjs powersoftau new bn128 14 pot14_0000.ptau -v
snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="dev" -v
snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v
snarkjs groth16 setup reward_check.r1cs pot14_final.ptau reward_check_0000.zkey
snarkjs zkey contribute reward_check_0000.zkey reward_check_final.zkey --name="dev" -v
snarkjs zkey export verificationkey reward_check_final.zkey verification_key.json
```

## Solidity Verifier

```bash
snarkjs zkey export solidityverifier reward_check_final.zkey ../contracts/RewardGroth16Verifier.sol
```

The generated verifier should be wired into `../contracts/RewardPool.sol`
through `IRewardVerifier`.

## Known Next Step

The v0 circuit uses ring peer matching to avoid dynamic array indexing. A later
version should support public peer assignments or derive peer assignments from a
public randomness seed.
