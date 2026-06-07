// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FinalStateRegistry {
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct FinalState {
        uint256 finalStateRoot;
        uint256 tallyResult;
        uint256 rewardRandomness;
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
        uint256 rewardRandomness,
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
        registerFinalStateWithMaciStatusAndRandomness(
            disputeId,
            finalStateRoot,
            tallyResult,
            _deriveRewardRandomness(disputeId, finalStateRoot, tallyResult),
            true
        );
    }

    function registerFinalStateWithMaciStatus(
        uint256 disputeId,
        uint256 finalStateRoot,
        uint256 tallyResult,
        bool maciTallyVerified
    ) public onlyOwner {
        registerFinalStateWithMaciStatusAndRandomness(
            disputeId,
            finalStateRoot,
            tallyResult,
            _deriveRewardRandomness(disputeId, finalStateRoot, tallyResult),
            maciTallyVerified
        );
    }

    function registerFinalStateWithRandomness(
        uint256 disputeId,
        uint256 finalStateRoot,
        uint256 tallyResult,
        uint256 rewardRandomness
    ) external onlyOwner {
        registerFinalStateWithMaciStatusAndRandomness(disputeId, finalStateRoot, tallyResult, rewardRandomness, true);
    }

    function registerFinalStateWithMaciStatusAndRandomness(
        uint256 disputeId,
        uint256 finalStateRoot,
        uint256 tallyResult,
        uint256 rewardRandomness,
        bool maciTallyVerified
    ) public onlyOwner {
        require(finalStateRoot != 0, "zero root");
        require(rewardRandomness != 0, "zero randomness");
        require(!finalStates[disputeId].finalized, "already finalized");

        finalStates[disputeId] =
            FinalState({
                finalStateRoot: finalStateRoot,
                tallyResult: tallyResult,
                rewardRandomness: rewardRandomness,
                maciTallyVerified: maciTallyVerified,
                finalized: true
            });

        emit FinalStateRegistered(disputeId, finalStateRoot, tallyResult, rewardRandomness, maciTallyVerified);
    }

    function isFinalized(uint256 disputeId) external view returns (bool) {
        return finalStates[disputeId].finalized;
    }

    function finalStateRootOf(uint256 disputeId) external view returns (uint256) {
        return finalStates[disputeId].finalStateRoot;
    }

    function rewardRandomnessOf(uint256 disputeId) external view returns (uint256) {
        return finalStates[disputeId].rewardRandomness;
    }

    function _deriveRewardRandomness(uint256 disputeId, uint256 finalStateRoot, uint256 tallyResult)
        internal
        pure
        returns (uint256)
    {
        return (uint256(keccak256(abi.encodePacked(disputeId, finalStateRoot, tallyResult))) % (SNARK_SCALAR_FIELD - 1)) + 1;
    }
}
