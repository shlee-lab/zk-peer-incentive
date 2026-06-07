// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/RewardGroth16Verifier.sol";
import "../contracts/RewardPool.sol";
import "../contracts/RewardVerifierAdapter.sol";
import "./RewardProofFixture.sol";

contract RewardPoolV2Test {
    uint256 internal constant FINAL_STATE_ROOT_SIGNAL_INDEX = 20;

    function testGeneratedVerifierAcceptsRealProofBoundToFinalStateRoot() public {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);
        uint256[] memory signals = RewardProofFixture.publicSignals();

        require(signals[FINAL_STATE_ROOT_SIGNAL_INDEX] != 0, "missing final root");
        require(adapter.verifyProof(RewardProofFixture.proof(), signals), "proof rejected");
    }

    function testRewardPoolAcceptsRealProofAndPayouts() public {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);
        RewardPool pool = new RewardPool(adapter);

        uint256 disputeId = pool.createDispute{value: RewardProofFixture.TOTAL_PAYOUT}();
        pool.submitPayouts(
            disputeId,
            RewardProofFixture.recipients(),
            RewardProofFixture.amounts(),
            RewardProofFixture.proof(),
            RewardProofFixture.publicSignals()
        );

        (bool finalized,) = pool.disputes(disputeId);
        require(finalized, "not finalized");
    }

    function testTamperedFinalStateRootRejected() public {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);

        uint256[] memory signals = RewardProofFixture.publicSignals();
        signals[FINAL_STATE_ROOT_SIGNAL_INDEX] = signals[FINAL_STATE_ROOT_SIGNAL_INDEX] + 1;

        require(!adapter.verifyProof(RewardProofFixture.proof(), signals), "tampered root accepted");
    }

    function testTamperedPayoutSignalRejected() public {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);
        RewardPool pool = new RewardPool(adapter);
        uint256 disputeId = pool.createDispute{value: RewardProofFixture.TOTAL_PAYOUT}();

        uint256[] memory signals = RewardProofFixture.publicSignals();
        signals[4] = signals[4] + 1;

        (bool ok,) = address(pool).call(
            abi.encodeCall(
                RewardPool.submitPayouts,
                (
                    disputeId,
                    RewardProofFixture.recipients(),
                    RewardProofFixture.amounts(),
                    RewardProofFixture.proof(),
                    signals
                )
            )
        );
        require(!ok, "tampered signal accepted");
    }

    function testTamperedProofRejected() public {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);

        bytes memory proof = RewardProofFixture.proof();
        proof[31] = bytes1(uint8(proof[31]) ^ 1);

        require(!adapter.verifyProof(proof, RewardProofFixture.publicSignals()), "tampered proof accepted");
    }

    receive() external payable {}
}
