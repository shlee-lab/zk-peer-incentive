// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IRewardVerifier.sol";

contract MockRewardVerifier is IRewardVerifier {
    bool public shouldVerify = true;

    function setShouldVerify(bool value) external {
        shouldVerify = value;
    }

    function verifyProof(bytes calldata, uint256[] calldata) external view returns (bool) {
        return shouldVerify;
    }
}
