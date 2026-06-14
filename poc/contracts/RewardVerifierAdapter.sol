// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IRewardVerifier.sol";
import "./RewardGroth16Verifier.sol";

contract RewardVerifierAdapter is IRewardVerifier {
    uint256 public constant PUBLIC_SIGNAL_COUNT = 34;

    Groth16Verifier public immutable verifier;

    constructor(Groth16Verifier verifier_) {
        verifier = verifier_;
    }

    function verifyProof(bytes calldata proof, uint256[] calldata publicSignals) external view returns (bool) {
        if (publicSignals.length != PUBLIC_SIGNAL_COUNT) {
            return false;
        }

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            abi.decode(proof, (uint256[2], uint256[2][2], uint256[2]));

        uint256[34] memory signals;
        for (uint256 i = 0; i < PUBLIC_SIGNAL_COUNT; i++) {
            signals[i] = publicSignals[i];
        }

        return verifier.verifyProof(a, b, c, signals);
    }
}
