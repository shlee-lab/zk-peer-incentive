# ZK Peer-Prediction Reward PoC

This PoC implements the engineering path for the reward layer described in
`../WINE_MODEL_NOTES.md`.

This repo keeps the reward layer modular. The official MACI stack is used as a
separate pinned baseline; the reward circuit and contracts here do not rewrite
MACI. The goal is to show that peer-prediction reward computation can be
verified over hidden reports and that a Solidity payout contract can be gated by
such a proof.

## Full MACI Baseline

The experimental real-MACI baseline is recorded in `maci_baseline.md`.
It uses the official MACI repository at pinned commit
`22106c8a2015f18709a32208ad2ad40b6f3fa8a5`, runs real local MACI signup,
encrypted vote publication, message processing, tally proof generation, on-chain
proof submission, and tally verification, then selects the unmodified-MACI
reward sidecar path.

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

### M2. MACI Reward Sidecar State Adapter

v2 binds the hidden reward inputs to a reward sidecar root designed to be derived
from unmodified MACI final poll state. MACI message processing remains in the
official baseline from M0.

Reward sidecar nonce commitments and leaves are:

```text
nonceCommitment_i = Poseidon(nonce_i, 0)
leaf_i = Poseidon(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i)
```

The circuit verifies a fixed-position Merkle opening for each of the 8 leaves
and requires every path to end at the public `finalStateRoot`
(`finalRewardStateRoot` in the MACI sidecar plan). The same root is also used as
lottery seed context, so the proof binds:

```text
hidden reports/nonces used for rewards == reports/nonce commitments committed in the reward sidecar state
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
node scripts/export_solidity_fixture.js artifacts/v2/proof.json artifacts/v2/public.json vectors/v2/reward_lottery_state.json test/RewardProofFixture.sol vectors/v2/reward_proof_fixture.json

forge build
forge test -vvv
```

Observed v2 circuit size:

- 19,867 non-linear constraints;
- 22 public inputs;
- 80 private inputs.

v2 tests:

- `npm run test:v2:circuit` rejects tampered private report, private nonce,
  nonce commitment, MACI state index, public stake, final root, and payout at
  witness-generation time.
- `forge test -vvv` verifies the real proof on-chain and rejects tampered
  public final root, tampered public payout signal, and tampered proof bytes.

v2 limitations:

- This is a reward sidecar root, not a replacement for the official MACI tally
  proof.
- The circuit verifies all 8 fixed-position leaves rather than a dynamic voter set.
- Voter IDs remain private witness values in this PoC.
- Stakes remain public but are included in every reward sidecar leaf.
- The local Groth16 ceremony remains development-only.

### M3. Integrated Finalize And Claim Flow

v3 adds an integrated Anvil flow with:

- `FinalStateRegistry`: a minimal final-state registry storing `disputeId`,
  `finalStateRoot`, a placeholder `tallyResult`, a `maciTallyVerified` flag, and
  a finalized flag;
- `IntegratedRewardPool`: a proof-gated reward pool that requires:
  - a funded dispute;
  - a registry-finalized `disputeId`;
  - a registry entry marked with verified MACI tally status;
  - proof public signal `disputeId` matching the finalized dispute;
  - proof public signal `finalStateRoot` matching the registry;
  - public payout signals matching submitted claim amounts;
  - a valid generated Groth16 proof;
- recipient claims after reward finalization;
- a local Anvil script that deploys, finalizes, claims, and prints addresses,
  tx hashes, gas, and balances.

#### v3 Commands

From `poc/`:

```bash
forge build
forge test -vvv
npm run e2e:anvil
```

The E2E script reads:

- `vectors/v2/reward_proof_fixture.json`
- Foundry artifacts in `out/`

It starts local Anvil automatically if `RPC_URL` is unset and
`http://127.0.0.1:8545` is not already reachable. To use an existing node:

```bash
RPC_URL=http://127.0.0.1:8545 npm run e2e:anvil
```

v3 test coverage:

- deploy registry/verifier/adapter/integrated pool;
- register final state;
- submit valid proof and finalize payouts;
- claim a payout;
- wrong root fails;
- wrong dispute ID fails;
- unverified MACI tally status fails;
- tampered proof fails;
- tampered public signals fail;
- double finalization fails.

v3 limitations:

- The registry is a sidecar adapter and status gate; official MACI tally
  generation and verification are exercised in the separate M0 baseline.
- The tally result is a placeholder integer.
- Recipient identity is not proven by the reward circuit.
- The proof binds rewards to final-state leaves, but does not prove how the
  final state was produced.
- ETH payouts are used for PoC simplicity.
- The Groth16 verifier and proof are generated from a local development setup.

Not included in the reward E2E in this repo:

- vendored or modified MACI contracts/circuits;
- a single combined script that runs official MACI and reward finalization
  together;
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
binds those private values to a public MACI reward sidecar root.

### Solidity Contracts

Files:

- `contracts/IRewardVerifier.sol`
- `contracts/MockRewardVerifier.sol`
- `contracts/RewardPool.sol`
- `contracts/RewardGroth16Verifier.sol`
- `contracts/RewardVerifierAdapter.sol`
- `contracts/FinalStateRegistry.sol`
- `contracts/IntegratedRewardPool.sol`

The integrated payout contract accepts proof-gated payout vectors only after a
matching reward sidecar root is registered with verified MACI tally status. The
generated Groth16 verifier is used through the adapter; the mock verifier is
retained only for separate sanity tests.

### Benchmarks

Run:

```bash
node scripts/benchmark_reference.js
```

This gives a reference computation benchmark. ZK proving time and verifier gas
require Circom/snarkjs/Foundry installation.

## Research Interpretation

The v3 PoC supports the limited claim:

> Lottery peer-prediction payouts can be represented as a ZK-verifiable relation
> over hidden reports/nonces, bound to a MACI reward sidecar root, and used in an
> integrated local finalize-and-claim reward flow with a real Solidity Groth16
> verifier. A separate pinned official MACI baseline demonstrates the unmodified
> MACI signup, encrypted voting, processing, tally proof, and tally verification
> flow that the sidecar is intended to attach to.

It does not prove effort exertion. Effort remains a game-theoretic incentive
claim from the model. The current reward E2E does not yet run the official MACI
flow and reward finalization in one combined script.
