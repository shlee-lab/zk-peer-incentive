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

    function registerAndFund(FinalStateRegistry registry, IntegratedRewardPool pool, uint256 disputeId, uint256 root)
        internal
    {
        registry.registerFinalState(disputeId, root, 1);
        pool.fundDispute{value: RewardProofFixture.TOTAL_PAYOUT}(disputeId);
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
        registerAndFund(registry, pool, disputeId, finalStateRoot);

        pool.finalizeRewards(disputeId, recipients, amounts, proof, publicSignals);

        uint256 winnerIndex = firstNonzeroAmountIndex(amounts);
        address claimant = recipients[winnerIndex];
        uint256 claimAmount = amounts[winnerIndex];
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
        registerAndFund(registry, pool, disputeId, finalStateRoot + 1);

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
        registry.registerFinalStateWithMaciStatus(disputeId, finalStateRoot, 1, false);
        pool.fundDispute{value: RewardProofFixture.TOTAL_PAYOUT}(disputeId);

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
        registerAndFund(registry, pool, wrongDisputeId, finalStateRoot);

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
        registerAndFund(registry, pool, disputeId, finalStateRoot);
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
        registerAndFund(registry, pool, disputeId, finalStateRoot);
        publicSignals[0] = publicSignals[0] + 1;

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "tampered signals accepted");
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
        registerAndFund(registry, pool, disputeId, finalStateRoot);

        pool.finalizeRewards(disputeId, recipients, amounts, proof, publicSignals);

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                IntegratedRewardPool.finalizeRewards,
                (disputeId, recipients, amounts, proof, publicSignals)
            )
        );
        require(!ok, "double finalization accepted");
    }

    receive() external payable {}
}
