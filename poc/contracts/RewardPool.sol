// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IRewardVerifier.sol";

contract RewardPool {
    struct Dispute {
        bool finalized;
        uint256 remainingBudget;
    }

    address public owner;
    IRewardVerifier public verifier;
    uint256 public nextDisputeId;

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => uint256)) public claimable;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VerifierUpdated(address indexed verifier);
    event DisputeCreated(uint256 indexed disputeId, uint256 budget);
    event PayoutsFinalized(uint256 indexed disputeId, uint256 totalPayout);
    event Claimed(uint256 indexed disputeId, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(IRewardVerifier initialVerifier) {
        owner = msg.sender;
        verifier = initialVerifier;
        emit OwnershipTransferred(address(0), msg.sender);
        emit VerifierUpdated(address(initialVerifier));
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

    function createDispute() external payable onlyOwner returns (uint256 disputeId) {
        require(msg.value > 0, "empty budget");
        disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({finalized: false, remainingBudget: msg.value});
        emit DisputeCreated(disputeId, msg.value);
    }

    function submitPayouts(
        uint256 disputeId,
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes calldata proof,
        uint256[] calldata publicSignals
    ) external {
        Dispute storage dispute = disputes[disputeId];
        require(!dispute.finalized, "already finalized");
        require(recipients.length == amounts.length, "length mismatch");
        require(publicSignals.length >= amounts.length, "missing payout signals");
        require(verifier.verifyProof(proof, publicSignals), "invalid proof");

        uint256 totalPayout = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "zero recipient");
            require(publicSignals[i] == amounts[i], "payout signal mismatch");
            claimable[disputeId][recipients[i]] += amounts[i];
            totalPayout += amounts[i];
        }

        require(totalPayout <= dispute.remainingBudget, "insufficient budget");
        dispute.remainingBudget -= totalPayout;
        dispute.finalized = true;

        emit PayoutsFinalized(disputeId, totalPayout);
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
        require(dispute.finalized, "not finalized");
        uint256 amount = dispute.remainingBudget;
        require(amount > 0, "no remainder");
        dispute.remainingBudget = 0;

        (bool ok,) = recipient.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
