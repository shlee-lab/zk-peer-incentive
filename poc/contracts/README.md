# Solidity PoC Contracts

These contracts are the minimal payout layer for the ZK reward PoC.

## Files

- `IRewardVerifier.sol`: generic verifier interface.
- `MockRewardVerifier.sol`: mock verifier for contract-flow tests.
- `RewardPool.sol`: ETH payout pool gated by a verifier proof.
- `RewardGroth16Verifier.sol`: generated snarkjs Groth16 verifier for the
  current v2/v3 circuit.
- `RewardVerifierAdapter.sol`: adapter from `bytes` proof and dynamic public
  signals to the generated verifier's fixed-array interface.
- `FinalStateRegistry.sol`: minimal reward sidecar registry with a MACI tally
  status flag.
- `IntegratedRewardPool.sol`: reward pool that binds proof public signals to
  the registry's `disputeId`, reward sidecar `finalStateRoot`, and payout
  recipients.

## Basic RewardPool Flow

1. Deploy a verifier.
2. Deploy `RewardPool(verifier)`.
3. Owner creates a funded dispute with `createDispute()`.
4. Prover submits recipients, amounts, proof, and public signals.
5. `RewardPool` checks:
   - verifier accepts the proof;
   - the first `amounts.length` public signals equal the payout amounts;
   - recipient public signals equal the submitted recipient addresses;
   - the funded budget covers total payout.
6. Recipients call `claim(disputeId)`.

## Integrated v3 Flow

1. Deploy generated `Groth16Verifier`.
2. Deploy `RewardVerifierAdapter`.
3. Deploy `FinalStateRegistry`.
4. Deploy `IntegratedRewardPool(adapter, registry)`.
5. Register `finalStateRoot` for the dispute in the registry with verified MACI
   tally status.
6. Fund the dispute in the reward pool.
7. Call `finalizeRewards` with recipients, payouts, proof, and public signals.
8. Recipients call `claim(disputeId)`.

`IntegratedRewardPool` checks that public signal index 28 equals `disputeId`
and index 29 equals the registry's `finalStateRoot`. It also checks recipient
public signals `8..15` against the submitted recipient addresses and requires
the registry entry's `maciTallyVerified` flag to be true.

## Connecting a Generated snarkjs Verifier

`snarkjs` generates verifier contracts with a typed Groth16 interface rather
than the generic `bytes` interface used by `RewardPool`.
`RewardVerifierAdapter` decodes `abi.encode(a, b, c)` and copies the 31 public
signals into the generated verifier's fixed-size array.

For a production contract, prefer a typed adapter and a stable proof/public
input ABI over raw `bytes` decoding.

## Local Foundry Sketch

Run:

```bash
forge build
forge test -vvv
```

The tests do not use external Foundry dependencies. They verify the real proof
through the generated verifier and check rejection of tampered proof data or
public payout signals. v3 tests also cover registry-bound finalization and
claims.

Run the local Anvil E2E flow:

```bash
npm run e2e:anvil
```

## Contract Scope

- The current payout layer uses ETH for a simple local E2E flow.
- The contract verifies proof-bound payouts, recipients, poll id, and reward
  state root before recording claimable balances.
- MACI vote processing, report derivation, and command-salt extraction are
  handled by the MACI-side adapter and reward proof generation scripts.
