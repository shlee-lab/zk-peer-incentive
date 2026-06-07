# Solidity PoC Contracts

These contracts are the minimal payout layer for the ZK reward PoC.

## Files

- `IRewardVerifier.sol`: generic verifier interface.
- `MockRewardVerifier.sol`: mock verifier for contract-flow tests.
- `RewardPool.sol`: ETH payout pool gated by a verifier proof.

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
than the generic `bytes` interface used here. Add a small adapter contract:

```solidity
contract RewardVerifierAdapter is IRewardVerifier {
    Groth16Verifier public immutable verifier;

    constructor(Groth16Verifier verifier_) {
        verifier = verifier_;
    }

    function verifyProof(bytes calldata proof, uint256[] calldata publicSignals)
        external
        view
        returns (bool)
    {
        // Decode proof into snarkjs verifier arguments, then call verifier.
        // The exact decoding depends on the generated verifier signature.
    }
}
```

For a production contract, prefer a typed adapter over raw `bytes` decoding.

## Local Foundry Sketch

When Foundry is installed:

```bash
forge init --no-commit .
forge test
```

The current repository does not include Foundry dependencies. The contracts are
kept import-free so they can be copied into a Foundry or Hardhat project without
OpenZeppelin.

## Limitations

- This is an ETH payout sketch, not an ERC20 integration.
- Recipient identity is not proven by the circuit in v0.
- The generated proof must bind `payoutScaled[i]` to public signals.
- The report-to-encrypted-vote consistency relation is an upstream MACI-like
  integration step.
