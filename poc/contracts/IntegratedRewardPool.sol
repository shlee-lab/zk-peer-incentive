// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./FinalStateRegistry.sol";
import "./IRewardVerifier.sol";

contract IntegratedRewardPool {
    uint256 public constant PAYOUT_COUNT = 8;
    uint256 public constant RECIPIENT_SIGNAL_OFFSET = 8;
    uint256 public constant STAKE_SIGNAL_OFFSET = 16;
    uint256 public constant SMOOTHING_SIGNAL_INDEX = 24;
    uint256 public constant KAPPA_SIGNAL_INDEX = 25;
    uint256 public constant SCALE_SIGNAL_INDEX = 26;
    uint256 public constant POLL_ID_SIGNAL_INDEX = 27;
    uint256 public constant FINAL_REWARD_STATE_ROOT_SIGNAL_INDEX = 28;
    uint256 public constant RHO_TAU_SIGNAL_INDEX = 29;
    uint256 public constant DISPUTE_ID_SIGNAL_INDEX = POLL_ID_SIGNAL_INDEX;
    uint256 public constant FINAL_STATE_ROOT_SIGNAL_INDEX = FINAL_REWARD_STATE_ROOT_SIGNAL_INDEX;

    struct Dispute {
        bool rewardsFinalized;
        uint256 remainingBudget;
    }

    address public owner;
    IRewardVerifier public verifier;
    FinalStateRegistry public registry;

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => uint256)) public claimable;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VerifierUpdated(address indexed verifier);
    event RegistryUpdated(address indexed registry);
    event DisputeFunded(uint256 indexed disputeId, uint256 budget);
    event RewardsFinalized(uint256 indexed disputeId, uint256 finalStateRoot, uint256 totalPayout);
    event Claimed(uint256 indexed disputeId, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(IRewardVerifier initialVerifier, FinalStateRegistry initialRegistry) {
        owner = msg.sender;
        verifier = initialVerifier;
        registry = initialRegistry;
        emit OwnershipTransferred(address(0), msg.sender);
        emit VerifierUpdated(address(initialVerifier));
        emit RegistryUpdated(address(initialRegistry));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setVerifier(IRewardVerifier newVerifier) external onlyOwner {
        verifier = newVerifier;
        emit VerifierUpdated(address(newVerifier));
    }

    function setRegistry(FinalStateRegistry newRegistry) external onlyOwner {
        registry = newRegistry;
        emit RegistryUpdated(address(newRegistry));
    }

    function fundDispute(uint256 disputeId) external payable onlyOwner {
        require(msg.value > 0, "empty budget");
        require(disputes[disputeId].remainingBudget == 0, "already funded");
        disputes[disputeId].remainingBudget = msg.value;
        emit DisputeFunded(disputeId, msg.value);
    }

    function finalizeRewards(
        uint256 disputeId,
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes calldata proof,
        uint256[] calldata publicSignals
    ) external {
        Dispute storage dispute = disputes[disputeId];
        require(!dispute.rewardsFinalized, "already finalized");
        require(dispute.remainingBudget > 0, "unfunded dispute");
        require(recipients.length == amounts.length, "length mismatch");
        require(amounts.length == PAYOUT_COUNT, "wrong payout count");
        require(publicSignals.length > RHO_TAU_SIGNAL_INDEX, "missing public signals");
        require(publicSignals[POLL_ID_SIGNAL_INDEX] == disputeId, "poll signal mismatch");

        uint256 finalStateRoot = _requireFinalStateRoot(disputeId);
        require(publicSignals[FINAL_REWARD_STATE_ROOT_SIGNAL_INDEX] == finalStateRoot, "root signal mismatch");
        require(verifier.verifyProof(proof, publicSignals), "invalid proof");

        uint256 totalPayout = _recordPayouts(disputeId, recipients, amounts, publicSignals);

        require(totalPayout <= dispute.remainingBudget, "insufficient budget");
        dispute.remainingBudget -= totalPayout;
        dispute.rewardsFinalized = true;

        emit RewardsFinalized(disputeId, finalStateRoot, totalPayout);
    }

    function _requireFinalStateRoot(uint256 disputeId) internal view returns (uint256 finalStateRoot) {
        bool finalStateFinalized;
        bool maciTallyVerified;
        (finalStateRoot,, maciTallyVerified, finalStateFinalized) = registry.finalStates(disputeId);
        require(finalStateFinalized, "final state missing");
        require(maciTallyVerified, "maci tally unverified");
    }

    function _recordPayouts(
        uint256 disputeId,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata publicSignals
    ) internal returns (uint256 totalPayout) {
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "zero recipient");
            require(publicSignals[i] == amounts[i], "payout signal mismatch");
            require(
                publicSignals[RECIPIENT_SIGNAL_OFFSET + i] == uint256(uint160(recipients[i])),
                "recipient signal mismatch"
            );
            claimable[disputeId][recipients[i]] += amounts[i];
            totalPayout += amounts[i];
        }
    }

    function claim(uint256 disputeId) external {
        uint256 amount = claimable[disputeId][msg.sender];
        require(amount > 0, "nothing to claim");
        claimable[disputeId][msg.sender] = 0;

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");

        emit Claimed(disputeId, msg.sender, amount);
    }

    function withdrawRemainder(uint256 disputeId, address payable recipient) external onlyOwner {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.rewardsFinalized, "not finalized");
        uint256 amount = dispute.remainingBudget;
        require(amount > 0, "no remainder");
        dispute.remainingBudget = 0;

        (bool ok,) = recipient.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
