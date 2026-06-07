// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/RewardGroth16Verifier.sol";
import "../contracts/RewardPool.sol";
import "../contracts/RewardVerifierAdapter.sol";
import "./RewardProofFixture.sol";

contract RewardPoolV1Test {
    function testGeneratedVerifierAcceptsRealProof() public {
        Groth16Verifier verifier = new Groth16Verifier();
        RewardVerifierAdapter adapter = new RewardVerifierAdapter(verifier);

        require(adapter.verifyProof(RewardProofFixture.proof(), RewardProofFixture.publicSignals()), "proof rejected");
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
