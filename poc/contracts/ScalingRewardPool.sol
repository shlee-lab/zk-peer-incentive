// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./FinalStateRegistry.sol";
import "./IRewardVerifier.sol";

contract ScalingRewardPool {
    struct Dispute {
        bool rewardsFinalized;
        uint256 remainingBudget;
    }

    address public owner;
    IRewardVerifier public verifier;
    FinalStateRegistry public registry;
    uint256 public immutable payoutCount;

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => uint256)) public claimable;

    event DisputeFunded(uint256 indexed disputeId, uint256 budget);
    event RewardsFinalized(uint256 indexed disputeId, uint256 finalStateRoot, uint256 totalPayout);
    event Claimed(uint256 indexed disputeId, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(IRewardVerifier initialVerifier, FinalStateRegistry initialRegistry, uint256 payoutCount_) {
        require(payoutCount_ > 0, "zero payout count");
        owner = msg.sender;
        verifier = initialVerifier;
        registry = initialRegistry;
        payoutCount = payoutCount_;
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
        uint256 n = payoutCount;
        uint256 randomSeedIndex = 3 * n + 9;
        Dispute storage dispute = disputes[disputeId];
        require(!dispute.rewardsFinalized, "already finalized");
        require(dispute.remainingBudget > 0, "unfunded dispute");
        require(recipients.length == n, "wrong recipient count");
        require(amounts.length == n, "wrong payout count");
        require(publicSignals.length == 3 * n + 10, "wrong public signal count");
        require(publicSignals[3 * n + 4] == disputeId, "poll signal mismatch");

        (uint256 finalStateRoot, uint256 randomSeed) = _requireFinalState(disputeId);
        require(publicSignals[3 * n + 5] == finalStateRoot, "root signal mismatch");
        require(publicSignals[randomSeedIndex] == randomSeed, "seed signal mismatch");
        require(dispute.remainingBudget >= n * publicSignals[3 * n + 3], "underfunded max exposure");
        require(verifier.verifyProof(proof, publicSignals), "invalid proof");

        uint256 totalPayout = _recordPayouts(disputeId, recipients, amounts, publicSignals);

        require(totalPayout <= dispute.remainingBudget, "insufficient budget");
        dispute.remainingBudget -= totalPayout;
        dispute.rewardsFinalized = true;

        emit RewardsFinalized(disputeId, finalStateRoot, totalPayout);
    }

    function _requireFinalState(uint256 disputeId) internal view returns (uint256 finalStateRoot, uint256 randomSeed) {
        bool finalStateFinalized;
        bool maciTallyVerified;
        bool randomSeedFinalized;
        (finalStateRoot,,, randomSeed, maciTallyVerified, finalStateFinalized, randomSeedFinalized) =
            registry.finalStates(disputeId);
        require(finalStateFinalized, "final state missing");
        require(maciTallyVerified, "maci tally unverified");
        require(randomSeedFinalized, "random seed missing");
    }

    function _recordPayouts(
        uint256 disputeId,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata publicSignals
    ) internal returns (uint256 totalPayout) {
        uint256 n = payoutCount;
        uint256 rhoTau = publicSignals[3 * n + 3];
        for (uint256 i = 0; i < n; i++) {
            require(recipients[i] != address(0), "zero recipient");
            require(publicSignals[i] == amounts[i], "payout signal mismatch");
            require(amounts[i] == 0 || amounts[i] == rhoTau, "non-bernoulli payout");
            require(publicSignals[n + i] == uint256(uint160(recipients[i])), "recipient signal mismatch");
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
}
