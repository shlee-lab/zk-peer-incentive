// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/FinalStateRegistry.sol";
import "../contracts/IntegratedRewardPool.sol";
import "../contracts/RewardGroth16Verifier.sol";
import "../contracts/RewardVerifierAdapter.sol";
import "./RewardProofFixture.sol";

interface Vm {
    function prank(address msgSender) external;
}

contract IntegratedRewardPoolV3Test {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function deployStack()
        internal
        returns (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        )
    {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);
        registry = new FinalStateRegistry();
        pool = new IntegratedRewardPool(adapter, registry);

        publicSignals = RewardProofFixture.publicSignals();
        disputeId = publicSignals[pool.DISPUTE_ID_SIGNAL_INDEX()];
        finalStateRoot = publicSignals[pool.FINAL_STATE_ROOT_SIGNAL_INDEX()];
        recipients = RewardProofFixture.recipients();
        amounts = RewardProofFixture.amounts();
        proof = RewardProofFixture.proof();
    }

    function registerAndFund(
        FinalStateRegistry registry,
        IntegratedRewardPool pool,
        uint256 disputeId,
        uint256 root,
        uint256[] memory publicSignals
    )
        internal
    {
        registry.commitRandomSeed(disputeId, RewardProofFixture.SEED_COMMITMENT);
        registry.registerFinalState(disputeId, root, 1);
        registry.revealRandomSeed(disputeId, RewardProofFixture.SEED_PREIMAGE, RewardProofFixture.SEED_SALT);
        pool.fundDispute{value: RewardProofFixture.PAYOUT_COUNT * publicSignals[pool.RHO_TAU_SIGNAL_INDEX()]}(disputeId);
    }

    function firstNonzeroAmountIndex(uint256[] memory amounts) internal pure returns (uint256) {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] != 0) {
                return i;
            }
        }
        revert("no nonzero payout");
    }

    function testFinalizeAndClaim() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);

        pool.finalizeRewards(disputeId, recipients, amounts, proof, publicSignals);

        uint256 paidIndex = firstNonzeroAmountIndex(amounts);
        address claimant = recipients[paidIndex];
        uint256 claimAmount = amounts[paidIndex];
        require(pool.claimable(disputeId, claimant) == claimAmount, "claimable mismatch");

        uint256 beforeBalance = claimant.balance;
        vm.prank(claimant);
        pool.claim(disputeId);

        require(pool.claimable(disputeId, claimant) == 0, "claimable not cleared");
        require(claimant.balance == beforeBalance + claimAmount, "claim not paid");
    }

    function testWrongRootFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot + 1, publicSignals);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "wrong root accepted");
    }

    function testUnverifiedMaciTallyFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registry.commitRandomSeed(disputeId, RewardProofFixture.SEED_COMMITMENT);
        registry.registerFinalStateWithMaciStatus(disputeId, finalStateRoot, 1, false);
        registry.revealRandomSeed(disputeId, RewardProofFixture.SEED_PREIMAGE, RewardProofFixture.SEED_SALT);
        pool.fundDispute{value: RewardProofFixture.PAYOUT_COUNT * publicSignals[pool.RHO_TAU_SIGNAL_INDEX()]}(disputeId);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "unverified maci tally accepted");
    }

    function testWrongDisputeIdFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        uint256 wrongDisputeId = disputeId + 1;
        registerAndFund(registry, pool, wrongDisputeId, finalStateRoot, publicSignals);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (wrongDisputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "wrong dispute accepted");
    }

    function testTamperedProofFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);
        proof[31] = bytes1(uint8(proof[31]) ^ 1);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "tampered proof accepted");
    }

    function testTamperedPublicSignalsFail() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);
        publicSignals[0] = publicSignals[0] + 1;

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "tampered signals accepted");
    }

    function testWrongRandomSeedFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);
        publicSignals[pool.RANDOM_SEED_SIGNAL_INDEX()] = publicSignals[pool.RANDOM_SEED_SIGNAL_INDEX()] + 1;

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "wrong random seed accepted");
    }

    function testUnderfundedMaxExposureFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registry.commitRandomSeed(disputeId, RewardProofFixture.SEED_COMMITMENT);
        registry.registerFinalState(disputeId, finalStateRoot, 1);
        registry.revealRandomSeed(disputeId, RewardProofFixture.SEED_PREIMAGE, RewardProofFixture.SEED_SALT);
        pool.fundDispute{value: publicSignals[pool.RHO_TAU_SIGNAL_INDEX()]}(disputeId);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "underfunded max exposure accepted");
    }

    function testTamperedRecipientFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);
        recipients[0] = address(uint160(uint256(keccak256(bytes("attacker recipient")))));

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "tampered recipient accepted");
    }

    function testDoubleFinalizationFails() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);

        pool.finalizeRewards(disputeId, recipients, amounts, proof, publicSignals);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "double finalization accepted");
    }

    function testWithdrawRemainderAfterFinalization() public {
        (
            FinalStateRegistry registry,
            IntegratedRewardPool pool,
            uint256 disputeId,
            uint256 finalStateRoot,
            address[] memory recipients,
            uint256[] memory amounts,
            bytes memory proof,
            uint256[] memory publicSignals
        ) = deployStack();
        registerAndFund(registry, pool, disputeId, finalStateRoot, publicSignals);

        pool.finalizeRewards(disputeId, recipients, amounts, proof, publicSignals);

        uint256 totalPayout;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalPayout += amounts[i];
        }
        uint256 funded = RewardProofFixture.PAYOUT_COUNT * publicSignals[pool.RHO_TAU_SIGNAL_INDEX()];
        require(address(pool).balance == funded, "unexpected pool balance before claims");
        (, uint256 remainingBefore) = pool.disputes(disputeId);
        require(remainingBefore == funded - totalPayout, "unexpected remainder");

        address payable recipient = payable(address(uint160(uint256(keccak256(bytes("remainder recipient"))))));
        uint256 beforeBalance = recipient.balance;
        pool.withdrawRemainder(disputeId, recipient);

        (, uint256 remainingAfter) = pool.disputes(disputeId);
        require(remainingAfter == 0, "remainder not cleared");
        require(recipient.balance == beforeBalance + funded - totalPayout, "remainder not withdrawn");
    }

    receive() external payable {}
}
