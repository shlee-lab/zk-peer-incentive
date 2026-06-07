# ZK Peer-Prediction Reward PoC

This PoC implements the engineering path for the reward layer described in
`../WINE_MODEL_NOTES.md`.

The goal is not to implement MACI. The goal is to show that peer-prediction
reward computation can be verified over hidden reports, and that a Solidity
payout contract can be gated by such a proof.

## Milestones

### M0. Scope

Baseline v0 scope:

- binary reports;
- public stakes;
- smoothed stake-weighted leave-one-out frequency;
- inverse-frequency peer agreement;
- fixed-point public payouts;
- ring peer matching in the circuit draft;
- generic Solidity verifier interface.

### M1. Lottery Reward Proof

v1 adds a real lottery payout proof:

- private binary reports;
- public stakes;
- private high-entropy nonces;
- Poseidon seed `H(nonce_0, ..., nonce_7, disputeId, stateRoot)`;
- per-voter draw `H(seed, i)`, using the low 32 bits as the PoC lottery draw;
- fixed-point expected reward from the inverse-frequency peer-agreement rule;
- public payout `rhoTau` when `draw_i * rhoTau < expected_i * 2^32`, else zero;
- Groth16 proof verified locally by `snarkjs`;
- generated Solidity verifier checked through `RewardVerifierAdapter` and `RewardPool` in Foundry.

The committed deterministic vector is:

- `vectors/v1/reward_lottery.json`

Generated local proving artifacts are written under:

- `artifacts/v1/input.json`
- `artifacts/v1/reward_check.r1cs`
- `artifacts/v1/reward_check_js/reward_check.wasm`
- `artifacts/v1/witness.wtns`
- `artifacts/v1/proof.json`
- `artifacts/v1/public.json`
- `artifacts/v1/verification_key.json`
- `artifacts/v1/reward_check_final.zkey`

`artifacts/` is ignored because these files are large and reproducible.

#### v1 Commands

From `poc/`:

```bash
npm install
npm run generate:v1
npm run test:reference

mkdir -p artifacts/v1
circom circuits/reward_check.circom --r1cs --wasm --sym -o artifacts/v1
npx snarkjs wtns calculate artifacts/v1/reward_check_js/reward_check.wasm artifacts/v1/input.json artifacts/v1/witness.wtns
npx snarkjs wtns check artifacts/v1/reward_check.r1cs artifacts/v1/witness.wtns

npx snarkjs powersoftau new bn128 14 artifacts/v1/pot14_0000.ptau
npx snarkjs powersoftau contribute artifacts/v1/pot14_0000.ptau artifacts/v1/pot14_0001.ptau --name="v1 dev contribution" -e="zk-peer-incentive-v1-pot"
npx snarkjs powersoftau prepare phase2 artifacts/v1/pot14_0001.ptau artifacts/v1/pot14_final.ptau
npx snarkjs groth16 setup artifacts/v1/reward_check.r1cs artifacts/v1/pot14_final.ptau artifacts/v1/reward_check_0000.zkey
npx snarkjs zkey contribute artifacts/v1/reward_check_0000.zkey artifacts/v1/reward_check_final.zkey --name="v1 dev zkey" -e="zk-peer-incentive-v1-zkey"
npx snarkjs zkey verify artifacts/v1/reward_check.r1cs artifacts/v1/pot14_final.ptau artifacts/v1/reward_check_final.zkey
npx snarkjs zkey export verificationkey artifacts/v1/reward_check_final.zkey artifacts/v1/verification_key.json
npx snarkjs groth16 prove artifacts/v1/reward_check_final.zkey artifacts/v1/witness.wtns artifacts/v1/proof.json artifacts/v1/public.json
npx snarkjs groth16 verify artifacts/v1/verification_key.json artifacts/v1/public.json artifacts/v1/proof.json
npx snarkjs zkey export solidityverifier artifacts/v1/reward_check_final.zkey contracts/RewardGroth16Verifier.sol
node scripts/export_solidity_fixture.js artifacts/v1/proof.json artifacts/v1/public.json vectors/v1/reward_lottery.json test/RewardProofFixture.sol

forge build
forge test -vvv
```

Observed v1 circuit size:

- 9,643 non-linear constraints;
- 22 public inputs;
- 32 private inputs.

v1 limitations:

- `stateRoot` is only seed context in v1; it is not yet proven to contain reports/nonces.
- Peer assignment is fixed as a ring, `peer(i) = i + 1 mod N`.
- `N = 8` is fixed.
- The Groth16 ceremony is local development setup only.
- The low-32-bit draw extraction is a simple PoC choice, not a production randomness design.

Not included in this PoC:

- full MACI message processing;
- proof that a voter actually exerted effort;
- coordinator privacy;
- Sybil defense;
- production receipt-freeness.

### Reference Model

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

### ZK Relation and Circuit

Files:

- `zk_relation.md`
- `circuits/reward_check.circom`

The v1 circuit verifies lottery payouts from private reports and nonces. It does
not yet bind reports to encrypted votes or final-state commitments.

### Solidity Contracts

Files:

- `contracts/IRewardVerifier.sol`
- `contracts/MockRewardVerifier.sol`
- `contracts/RewardPool.sol`
- `contracts/RewardGroth16Verifier.sol`
- `contracts/RewardVerifierAdapter.sol`

The payout contract accepts proof-gated payout vectors and lets recipients claim
ETH rewards. v1 Foundry tests use the generated Groth16 verifier through the
adapter; the mock verifier is retained only for separate sanity tests.

### Benchmarks

Run:

```bash
node scripts/benchmark_reference.js
```

This gives a reference computation benchmark. ZK proving time and verifier gas
require Circom/snarkjs/Foundry installation.

## Research Interpretation

The v1 PoC supports the limited claim:

> Lottery peer-prediction payouts can be represented as a ZK-verifiable relation
> over hidden reports/nonces and used to gate public payouts with a real
> Solidity Groth16 verifier.

It does not prove effort exertion. Effort remains a game-theoretic incentive
claim from the model. It does not implement full MACI.
