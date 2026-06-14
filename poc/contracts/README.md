# Solidity PoC Contracts

These contracts are the minimal payout layer for the ZK reward prototype. They
are written for a local research run, not for production deployment.

## Files

- `IRewardVerifier.sol`: generic verifier interface.
- `MockRewardVerifier.sol`: mock verifier for separate contract-flow tests.
- `RewardPool.sol`: simple verifier-gated ETH pool used by older sanity tests.
- `RewardGroth16Verifier.sol`: snarkjs-generated Groth16 verifier for the
  current reward circuit.
- `RewardVerifierAdapter.sol`: adapter from `bytes` proof data and dynamic
  public signals to the generated verifier's fixed-array interface.
- `FinalStateRegistry.sol`: reward sidecar registry with MACI tally status and
  commit-reveal seed sequencing.
- `IntegratedRewardPool.sol`: registry-bound pool that verifies the reward
  proof, records claimable balances, and pays claims.

## Integrated Flow

The current Anvil flow is:

```text
commit random seed
register final reward state root with MACI tally status
reveal random seed
fund pool for N * rhoTau maximum exposure
verify reward proof and finalize payouts
recipient claims
```

`FinalStateRegistry` enforces that the seed commitment exists before root
registration and that the seed is revealed after the root is registered.
`IntegratedRewardPool` then checks:

- MACI tally status is marked verified;
- public signal `disputeId` matches the registry entry;
- public signal `finalStateRoot` matches the registry entry;
- public signal `randomSeed` matches the revealed registry seed;
- submitted recipients match public signals `8..15`;
- submitted amounts match public signals `0..7`;
- every payout is binary, either `0` or `rhoTau`;
- the pool has at least `N * rhoTau` remaining before finalization;
- the Groth16 proof verifies.

The contract does not require `sum_i payout_i == rewardBudget`. Under the
Bernoulli rule the total payout is random. Unpaid balance remains in the pool
and can be withdrawn through the owner remainder path after finalization.

The contract does not interpret `psiScaled` directly; it is a verifier public
signal enforced by the circuit. The pool only checks registry binding, binary
payout shape, funding, and proof validity.

## Public Signal Order

`IntegratedRewardPool` and `RewardVerifierAdapter` expect 34 public signals:

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

`RewardVerifierAdapter` decodes `abi.encode(a, b, c)` and copies those 34
signals into the generated verifier's fixed-size array.

## Local Commands

From `poc/`:

```bash
forge build
forge test -vvv
npm run e2e:anvil
```

The tests verify the real Groth16 proof through the generated verifier and
check rejection of tampered proof data, roots, seeds, payout signals, and
double finalization.
