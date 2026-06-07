# ZK Peer-Prediction Reward PoC

This PoC implements the engineering path for the reward layer described in
`../WINE_MODEL_NOTES.md`.

The goal is not to implement MACI. The goal is to show that peer-prediction
reward computation can be verified over hidden reports, and that a Solidity
payout contract can be gated by such a proof.

## Milestones

### M0. Scope

Current v0 scope:

- binary reports;
- public stakes;
- smoothed stake-weighted leave-one-out frequency;
- inverse-frequency peer agreement;
- fixed-point public payouts;
- ring peer matching in the circuit draft;
- generic Solidity verifier interface.

Not included in v0:

- full MACI message processing;
- proof that a voter actually exerted effort;
- coordinator privacy;
- Sybil defense;
- production receipt-freeness.

### M1. Reference Model

Files:

- `reference/reward_model.js`
- `reference/test_reward_model.js`

Run:

```bash
node reference/test_reward_model.js
```

This checks:

- reward recomputation and tamper detection;
- matched-weighting neutrality;
- mismatched-weighting payout bias;
- self-calibration under account-level leave-one-out.

### M2. ZK Relation and Circuit Draft

Files:

- `zk_relation.md`
- `circuits/reward_check.circom`

The circuit verifies fixed-point payouts from private reports. It does not yet
bind reports to encrypted votes or commitments.

### M3. Solidity Contracts

Files:

- `contracts/IRewardVerifier.sol`
- `contracts/MockRewardVerifier.sol`
- `contracts/RewardPool.sol`

The payout contract accepts proof-gated payout vectors and lets recipients claim
ETH rewards.

### M4. Benchmarks

Run:

```bash
node scripts/benchmark_reference.js
```

This gives a reference computation benchmark. ZK proving time and verifier gas
require Circom/snarkjs/Foundry installation.

## Tool-Dependent Next Steps

After installing Circom and snarkjs:

```bash
cd circuits
circom reward_check.circom --r1cs --wasm --sym
```

Then run a local Groth16 ceremony and export a Solidity verifier as described in
`circuits/README.md`.

After installing Foundry or setting up Hardhat:

- compile contracts;
- deploy `MockRewardVerifier` and `RewardPool`;
- add a contract-flow test;
- replace the mock verifier with a generated verifier adapter.

## Research Interpretation

The PoC supports the limited claim:

> Peer-prediction reward computation can be represented as a ZK-verifiable
> relation and used to gate public payouts.

It does not prove effort exertion. Effort remains a game-theoretic incentive
claim from the model.
