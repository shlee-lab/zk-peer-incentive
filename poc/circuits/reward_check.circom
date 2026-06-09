pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// Reward-check circuit for binary reports, ring peer matching, fixed-budget
// lottery reward allocation, and MACI reward-sidecar state root binding.
//
// Public signals are ordered with payouts first so RewardPool can compare
// publicSignals[0..N-1] directly with submitted claim amounts.
//
// Public:
// - payouts[i]
// - recipients[i]
// - stakes[i]
// - smoothing
// - kappa
// - scale
// - rhoTau
// - disputeId (used as pollId for the MACI sidecar integration)
// - finalStateRoot (the reward sidecar root)
// - rewardBudget
//
// Private witness:
// - reports[i]
// - nonces[i]
// - maciStateIndices[i]
// - voterIds[i]
// - nonceCommitments[i]
// - merklePathElements[i][d]
// - expectedScaled[i]
// - rewardRemainders[i]
// - allocationRemainders[i]
//
// The expected reward is:
// floor(kappa * stake_i * agreement_i * D_i * scale / B_i) = expectedScaled_i
//
// where:
// D_i = sum_{j != i} stake_j + 2*smoothing
// N_i = sum_{j != i} stake_j * report_j + smoothing
// B_i = report_i * N_i + (1-report_i) * (D_i-N_i)
// The lottery seed is a Poseidon fold over the context and all included
// nonces:
// seed_0 = Poseidon(disputeId, finalStateRoot)
// seed_{i+1} = Poseidon(seed_i, nonce_i)
// Each draw is the low 32 bits of Poseidon(seed, i).
// Voter i wins the lottery if:
// draw_i * rhoTau < expectedScaled_i * 2^32
//
// The fixed-budget allocation score is active_i * scale + win_i * rhoTau, where
// active_i is implied by stake_i > 0. The scale-sized baseline keeps the total
// allocation denominator nonzero for active voters and gives an equal fallback
// when there are no lottery winners. Zero-stake padding leaves receive score 0.
// Payouts 0..N-2 are floor(rewardBudget * score_i / sum(score)); payout N-1
// receives the deterministic rounding residue so sum(payouts) equals
// rewardBudget exactly.
//
// Each reward sidecar leaf is:
// Poseidon(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i, recipient_i).
// The circuit privately opens nonce_i and checks:
// nonceCommitment_i = Poseidon(nonce_i, 0).
// It then verifies a fixed-position Merkle path for every voter and requires each
// path to end at finalStateRoot.
//
template RewardCheck(N, DEPTH, NBITS, LOTTERY_BITS) {
    signal input reports[N];
    signal input nonces[N];
    signal input maciStateIndices[N];
    signal input voterIds[N];
    signal input nonceCommitments[N];
    signal input merklePathElements[N][DEPTH];
    signal input expectedScaled[N];
    signal input rewardRemainders[N];
    signal input allocationRemainders[N];

    signal input payouts[N];
    signal input recipients[N];
    signal input stakes[N];
    signal input smoothing;
    signal input kappa;
    signal input scale;
    signal input rhoTau;
    signal input disputeId;
    signal input finalStateRoot;
    signal input rewardBudget;

    signal totalStake;
    signal totalOneStake;
    signal weightedReport[N];

    component leafHash[N];
    component nonceCommitmentHash[N];
    component merkleHash[N][DEPTH];
    signal merkleNode[N][DEPTH + 1];

    component stakeRange[N];
    component payoutRange[N];
    component recipientRange[N];
    component expectedRange[N];
    component remainderRange[N];
    component allocationRemainderRange[N];
    component stakeZero[N];
    component smoothingRange = Num2Bits(32);
    component kappaRange = Num2Bits(32);
    component scaleRange = Num2Bits(32);
    component rhoTauRange = Num2Bits(64);
    component rhoTauZero = IsZero();
    component rewardBudgetRange = Num2Bits(64);

    smoothingRange.in <== smoothing;
    kappaRange.in <== kappa;
    scaleRange.in <== scale;
    rhoTauRange.in <== rhoTau;
    rhoTauZero.in <== rhoTau;
    rhoTauZero.out === 0;
    rewardBudgetRange.in <== rewardBudget;

    var totalStakeExpr = 0;
    var totalOneStakeExpr = 0;
    for (var i = 0; i < N; i++) {
        reports[i] * (reports[i] - 1) === 0;
        stakeRange[i] = Num2Bits(32);
        stakeRange[i].in <== stakes[i];
        stakeZero[i] = IsZero();
        stakeZero[i].in <== stakes[i];
        payoutRange[i] = Num2Bits(64);
        payoutRange[i].in <== payouts[i];
        recipientRange[i] = Num2Bits(160);
        recipientRange[i].in <== recipients[i];
        expectedRange[i] = Num2Bits(64);
        expectedRange[i].in <== expectedScaled[i];
        remainderRange[i] = Num2Bits(NBITS);
        remainderRange[i].in <== rewardRemainders[i];

        nonceCommitmentHash[i] = Poseidon(2);
        nonceCommitmentHash[i].inputs[0] <== nonces[i];
        nonceCommitmentHash[i].inputs[1] <== 0;
        nonceCommitmentHash[i].out === nonceCommitments[i];

        leafHash[i] = Poseidon(6);
        leafHash[i].inputs[0] <== maciStateIndices[i];
        leafHash[i].inputs[1] <== voterIds[i];
        leafHash[i].inputs[2] <== reports[i];
        leafHash[i].inputs[3] <== nonceCommitments[i];
        leafHash[i].inputs[4] <== stakes[i];
        leafHash[i].inputs[5] <== recipients[i];
        merkleNode[i][0] <== leafHash[i].out;

        for (var d = 0; d < DEPTH; d++) {
            merkleHash[i][d] = Poseidon(2);
            if (((i >> d) & 1) == 0) {
                merkleHash[i][d].inputs[0] <== merkleNode[i][d];
                merkleHash[i][d].inputs[1] <== merklePathElements[i][d];
            } else {
                merkleHash[i][d].inputs[0] <== merklePathElements[i][d];
                merkleHash[i][d].inputs[1] <== merkleNode[i][d];
            }
            merkleNode[i][d + 1] <== merkleHash[i][d].out;
        }
        merkleNode[i][DEPTH] === finalStateRoot;

        weightedReport[i] <== stakes[i] * reports[i];
        totalStakeExpr += stakes[i];
        totalOneStakeExpr += weightedReport[i];
    }

    totalStake <== totalStakeExpr;
    totalOneStake <== totalOneStakeExpr;

    signal D[N];
    signal NOne[N];
    signal denomSelector[N];
    signal B[N];
    signal peerDiff[N];
    signal agreement[N];
    signal t1[N];
    signal t2[N];
    signal t3[N];
    signal numerator[N];
    signal rhs[N];
    signal remLessThanDenom[N];
    signal seed;
    signal draw[N];
    signal drawHashOut[N];
    signal lotteryLhs[N];
    signal lotteryRhs[N];
    signal win[N];
    signal active[N];
    signal allocationBaselineScore[N];
    signal allocationLotteryScore[N];
    signal allocationScore[N];
    signal totalAllocationScore;
    signal allocationNumerator[N];
    signal allocationRhs[N];
    signal allocationRemLessThanTotal[N];
    signal payoutSum;

    component remBound[N];
    component expectedLeRhoTau[N];
    component seedHash[N + 1];
    component drawHash[N];
    component drawBits[N];
    component lotteryBound[N];
    component allocationRemBound[N];

    signal seedAcc[N + 1];
    seedHash[0] = Poseidon(2);
    seedHash[0].inputs[0] <== disputeId;
    seedHash[0].inputs[1] <== finalStateRoot;
    seedAcc[0] <== seedHash[0].out;
    for (var i = 0; i < N; i++) {
        seedHash[i + 1] = Poseidon(2);
        seedHash[i + 1].inputs[0] <== seedAcc[i];
        seedHash[i + 1].inputs[1] <== nonces[i];
        seedAcc[i + 1] <== seedHash[i + 1].out;
    }
    seed <== seedAcc[N];

    var totalAllocationScoreExpr = 0;
    var payoutSumExpr = 0;
    for (var i = 0; i < N; i++) {
        D[i] <== totalStake - stakes[i] + 2 * smoothing;
        NOne[i] <== totalOneStake - weightedReport[i] + smoothing;
        denomSelector[i] <== 2 * NOne[i] - D[i];
        B[i] <== D[i] - NOne[i] + reports[i] * denomSelector[i];

        // Ring peer: peer(i) = i+1 mod N.
        if (i + 1 < N) {
            peerDiff[i] <== reports[i] - reports[i + 1];
        } else {
            peerDiff[i] <== reports[i] - reports[0];
        }
        agreement[i] <== 1 - peerDiff[i] * peerDiff[i];

        t1[i] <== kappa * stakes[i];
        t2[i] <== t1[i] * agreement[i];
        t3[i] <== t2[i] * D[i];
        numerator[i] <== t3[i] * scale;

        rhs[i] <== expectedScaled[i] * B[i] + rewardRemainders[i];
        numerator[i] === rhs[i];

        remBound[i] = LessThan(NBITS);
        remBound[i].in[0] <== rewardRemainders[i];
        remBound[i].in[1] <== B[i];
        remLessThanDenom[i] <== remBound[i].out;
        remLessThanDenom[i] === 1;

        expectedLeRhoTau[i] = LessThan(NBITS);
        expectedLeRhoTau[i].in[0] <== expectedScaled[i];
        expectedLeRhoTau[i].in[1] <== rhoTau + 1;
        expectedLeRhoTau[i].out === 1;

        drawHash[i] = Poseidon(2);
        drawHash[i].inputs[0] <== seed;
        drawHash[i].inputs[1] <== i;
        drawHashOut[i] <== drawHash[i].out;

        drawBits[i] = Num2Bits(254);
        drawBits[i].in <== drawHashOut[i];
        var drawExpr = 0;
        var twoPow = 1;
        for (var b = 0; b < LOTTERY_BITS; b++) {
            drawExpr += drawBits[i].out[b] * twoPow;
            twoPow = twoPow + twoPow;
        }
        draw[i] <== drawExpr;

        lotteryLhs[i] <== draw[i] * rhoTau;
        lotteryRhs[i] <== expectedScaled[i] * (2 ** LOTTERY_BITS);
        lotteryBound[i] = LessThan(NBITS);
        lotteryBound[i].in[0] <== lotteryLhs[i];
        lotteryBound[i].in[1] <== lotteryRhs[i];
        win[i] <== lotteryBound[i].out;

        active[i] <== 1 - stakeZero[i].out;
        allocationBaselineScore[i] <== active[i] * scale;
        allocationLotteryScore[i] <== win[i] * rhoTau;
        allocationScore[i] <== allocationBaselineScore[i] + allocationLotteryScore[i];
        totalAllocationScoreExpr += allocationScore[i];
        payoutSumExpr += payouts[i];
    }
    totalAllocationScore <== totalAllocationScoreExpr;
    payoutSum <== payoutSumExpr;
    payoutSum === rewardBudget;

    for (var i = 0; i < N; i++) {
        allocationRemainderRange[i] = Num2Bits(NBITS);
        allocationRemainderRange[i].in <== allocationRemainders[i];
        if (i + 1 < N) {
            allocationNumerator[i] <== rewardBudget * allocationScore[i];
            allocationRhs[i] <== payouts[i] * totalAllocationScore + allocationRemainders[i];
            allocationNumerator[i] === allocationRhs[i];

            allocationRemBound[i] = LessThan(NBITS);
            allocationRemBound[i].in[0] <== allocationRemainders[i];
            allocationRemBound[i].in[1] <== totalAllocationScore;
            allocationRemLessThanTotal[i] <== allocationRemBound[i].out;
            allocationRemLessThanTotal[i] === 1;
        } else {
            allocationRemainders[i] === 0;
        }
    }
}

component main { public [payouts, recipients, stakes, smoothing, kappa, scale, rhoTau, disputeId, finalStateRoot, rewardBudget] } = RewardCheck(8, 3, 128, 32);
