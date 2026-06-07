# Solidity PoC Contracts

These contracts are the minimal payout layer for the ZK reward PoC.

## Files

- `IRewardVerifier.sol`: generic verifier interface.
- `MockRewardVerifier.sol`: mock verifier for contract-flow tests.
- `RewardPool.sol`: ETH payout pool gated by a verifier proof.
- `RewardGroth16Verifier.sol`: generated snarkjs Groth16 verifier for v1.
- `RewardVerifierAdapter.sol`: adapter from `bytes` proof and dynamic public
  signals to the generated verifier's fixed-array interface.

## Flow

1. Deploy a verifier.
2. Deploy `RewardPool(verifier)`.
3. Owner creates a funded dispute with `createDispute()`.
4. Prover submits recipients, amounts, proof, and public signals.
5. `RewardPool` checks:
   - verifier accepts the proof;
   - the first `amounts.length` public signals equal the payout amounts;
   - the funded budget covers total payout.
6. Recipients call `claim(disputeId)`.

## Connecting a Generated snarkjs Verifier

`snarkjs` generates verifier contracts with a typed Groth16 interface rather
than the generic `bytes` interface used by `RewardPool`.
`RewardVerifierAdapter` decodes `abi.encode(a, b, c)` and copies the 22 public
signals into the generated verifier's fixed-size array.

For a production contract, prefer a typed adapter and a stable proof/public
input ABI over raw `bytes` decoding.

## Local Foundry Sketch

Run:

```bash
forge build
forge test -vvv
```

The tests do not use external Foundry dependencies. They verify the real v1
proof through the generated verifier and check rejection of tampered proof data
or public payout signals.

## Limitations

- This is an ETH payout sketch, not an ERC20 integration.
- Recipient identity is not proven by the circuit in v0.
- The generated proof must bind `payoutScaled[i]` to public signals.
- The report-to-encrypted-vote consistency relation is an upstream MACI-like
  integration step.
