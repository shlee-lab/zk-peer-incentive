// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IRewardVerifier.sol";

contract ScalingVerifierGasProbe {
    event ProofVerified(address indexed verifier);

    function verify(
        IRewardVerifier verifier,
        bytes calldata proof,
        uint256[] calldata publicSignals
    ) external returns (bool) {
        require(verifier.verifyProof(proof, publicSignals), "invalid proof");
        emit ProofVerified(address(verifier));
        return true;
    }
}
