// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FinalStateRegistry {
    struct FinalState {
        uint256 finalStateRoot;
        uint256 tallyResult;
        bool maciTallyVerified;
        bool finalized;
    }

    address public owner;
    mapping(uint256 => FinalState) public finalStates;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FinalStateRegistered(
        uint256 indexed disputeId,
        uint256 finalStateRoot,
        uint256 tallyResult,
        bool maciTallyVerified
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function registerFinalState(uint256 disputeId, uint256 finalStateRoot, uint256 tallyResult) external onlyOwner {
        registerFinalStateWithMaciStatus(disputeId, finalStateRoot, tallyResult, true);
    }

    function registerFinalStateWithMaciStatus(
        uint256 disputeId,
        uint256 finalStateRoot,
        uint256 tallyResult,
        bool maciTallyVerified
    ) public onlyOwner {
        require(finalStateRoot != 0, "zero root");
        require(!finalStates[disputeId].finalized, "already finalized");

        finalStates[disputeId] =
            FinalState({
                finalStateRoot: finalStateRoot,
                tallyResult: tallyResult,
                maciTallyVerified: maciTallyVerified,
                finalized: true
            });

        emit FinalStateRegistered(disputeId, finalStateRoot, tallyResult, maciTallyVerified);
    }

    function isFinalized(uint256 disputeId) external view returns (bool) {
        return finalStates[disputeId].finalized;
    }

    function finalStateRootOf(uint256 disputeId) external view returns (uint256) {
        return finalStates[disputeId].finalStateRoot;
    }
}
