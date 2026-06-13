// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FinalStateRegistry {
    uint256 public constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct FinalState {
        uint256 finalStateRoot;
        uint256 tallyResult;
        bytes32 seedCommitment;
        uint256 randomSeed;
        bool maciTallyVerified;
        bool finalized;
        bool randomSeedFinalized;
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
    event RandomSeedCommitted(uint256 indexed disputeId, bytes32 seedCommitment);
    event RandomSeedRevealed(uint256 indexed disputeId, uint256 randomSeed);

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

    function commitRandomSeed(uint256 disputeId, bytes32 seedCommitment) external onlyOwner {
        require(seedCommitment != bytes32(0), "zero seed commitment");
        FinalState storage state = finalStates[disputeId];
        require(!state.finalized, "already finalized");
        require(state.seedCommitment == bytes32(0), "seed already committed");
        state.seedCommitment = seedCommitment;
        emit RandomSeedCommitted(disputeId, seedCommitment);
    }

    function registerFinalStateWithMaciStatus(
        uint256 disputeId,
        uint256 finalStateRoot,
        uint256 tallyResult,
        bool maciTallyVerified
    ) public onlyOwner {
        require(finalStateRoot != 0, "zero root");
        require(!finalStates[disputeId].finalized, "already finalized");
        require(finalStates[disputeId].seedCommitment != bytes32(0), "seed commitment missing");

        bytes32 seedCommitment = finalStates[disputeId].seedCommitment;
        finalStates[disputeId] =
            FinalState({
                finalStateRoot: finalStateRoot,
                tallyResult: tallyResult,
                seedCommitment: seedCommitment,
                randomSeed: 0,
                maciTallyVerified: maciTallyVerified,
                finalized: true,
                randomSeedFinalized: false
            });

        emit FinalStateRegistered(disputeId, finalStateRoot, tallyResult, maciTallyVerified);
    }

    function revealRandomSeed(uint256 disputeId, uint256 seedPreimage, bytes32 salt) external onlyOwner {
        FinalState storage state = finalStates[disputeId];
        require(state.finalized, "final state missing");
        require(!state.randomSeedFinalized, "seed already finalized");
        require(
            keccak256(abi.encodePacked(seedPreimage, salt)) == state.seedCommitment,
            "seed commitment mismatch"
        );

        state.randomSeed =
            uint256(keccak256(abi.encodePacked(seedPreimage, salt, disputeId, state.finalStateRoot)))
                % SNARK_SCALAR_FIELD;
        state.randomSeedFinalized = true;
        emit RandomSeedRevealed(disputeId, state.randomSeed);
    }

    function isFinalized(uint256 disputeId) external view returns (bool) {
        return finalStates[disputeId].finalized;
    }

    function finalStateRootOf(uint256 disputeId) external view returns (uint256) {
        return finalStates[disputeId].finalStateRoot;
    }
}
