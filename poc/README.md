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

### M2. MACI-Like Final State Adapter

v2 binds the hidden reward inputs to a MACI-like final state root without
implementing MACI message processing.

Final state leaves are:

```text
leaf_i = Poseidon(voterId_i, report_i, nonce_i, stake_i)
```

The circuit verifies a fixed-position Merkle opening for each of the 8 leaves
and requires every path to end at the public `finalStateRoot`. The same
`finalStateRoot` is also used as lottery seed context, so the proof binds:

```text
hidden reports/nonces used for rewards == hidden reports/nonces committed in final state
```

The committed deterministic vector is:

- `vectors/v2/reward_lottery_state.json`

Generated local proving artifacts are written under:

- `artifacts/v2/input.json`
- `artifacts/v2/reward_check.r1cs`
- `artifacts/v2/reward_check_js/reward_check.wasm`
- `artifacts/v2/witness.wtns`
- `artifacts/v2/proof.json`
- `artifacts/v2/public.json`
- `artifacts/v2/verification_key.json`
- `artifacts/v2/reward_check_final.zkey`

#### v2 Commands

From `poc/`:

```bash
npm run generate:v2
npm run test:reference

mkdir -p artifacts/v2
circom circuits/reward_check.circom --r1cs --wasm --sym -o artifacts/v2
npx snarkjs wtns calculate artifacts/v2/reward_check_js/reward_check.wasm artifacts/v2/input.json artifacts/v2/witness.wtns
npx snarkjs wtns check artifacts/v2/reward_check.r1cs artifacts/v2/witness.wtns
npm run test:v2:circuit

npx snarkjs powersoftau new bn128 15 artifacts/v2/pot15_0000.ptau
npx snarkjs powersoftau contribute artifacts/v2/pot15_0000.ptau artifacts/v2/pot15_0001.ptau --name="v2 dev contribution" -e="zk-peer-incentive-v2-pot"
npx snarkjs powersoftau prepare phase2 artifacts/v2/pot15_0001.ptau artifacts/v2/pot15_final.ptau
npx snarkjs groth16 setup artifacts/v2/reward_check.r1cs artifacts/v2/pot15_final.ptau artifacts/v2/reward_check_0000.zkey
npx snarkjs zkey contribute artifacts/v2/reward_check_0000.zkey artifacts/v2/reward_check_final.zkey --name="v2 dev zkey" -e="zk-peer-incentive-v2-zkey"
npx snarkjs zkey verify artifacts/v2/reward_check.r1cs artifacts/v2/pot15_final.ptau artifacts/v2/reward_check_final.zkey
npx snarkjs zkey export verificationkey artifacts/v2/reward_check_final.zkey artifacts/v2/verification_key.json
npx snarkjs groth16 prove artifacts/v2/reward_check_final.zkey artifacts/v2/witness.wtns artifacts/v2/proof.json artifacts/v2/public.json
npx snarkjs groth16 verify artifacts/v2/verification_key.json artifacts/v2/public.json artifacts/v2/proof.json
npx snarkjs zkey export solidityverifier artifacts/v2/reward_check_final.zkey contracts/RewardGroth16Verifier.sol
node scripts/export_solidity_fixture.js artifacts/v2/proof.json artifacts/v2/public.json vectors/v2/reward_lottery_state.json test/RewardProofFixture.sol

forge build
forge test -vvv
```

Observed v2 circuit size:

- 17,779 non-linear constraints;
- 22 public inputs;
- 64 private inputs.

v2 tests:

- `npm run test:v2:circuit` rejects tampered private report, private nonce,
  final root, and payout at witness-generation time.
- `forge test -vvv` verifies the real proof on-chain and rejects tampered
  public final root, tampered public payout signal, and tampered proof bytes.

v2 limitations:

- This is a MACI-like final-state adapter, not MACI.
- The circuit verifies all 8 fixed-position leaves rather than a dynamic voter set.
- Voter IDs remain private witness values in this PoC.
- Stakes remain public but are included in every final-state leaf.
- The local Groth16 ceremony remains development-only.

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

The v2 circuit verifies lottery payouts from private reports and nonces and
binds those private values to a public MACI-like final-state root.

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

The v2 PoC supports the limited claim:

> Lottery peer-prediction payouts can be represented as a ZK-verifiable relation
> over hidden reports/nonces, bound to a MACI-like final-state root, and used to
> gate public payouts with a real Solidity Groth16 verifier.

It does not prove effort exertion. Effort remains a game-theoretic incentive
claim from the model. It does not implement full MACI.
