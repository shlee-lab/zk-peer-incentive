pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// Reward-check circuit for binary reports, ring peer matching, coordinate-wise
// Bernoulli lottery payouts, and MACI reward-sidecar state root binding.
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
// - rewardBudget (expected payout cap)
// - gammaScaled (gamma * 2^LOTTERY_BITS)
// - randomSeed (external seed fixed after finalStateRoot registration)
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
// - rawThresholds[i]
// - thresholdRemainders[i]
//
// The expected reward is:
// floor(kappa * stake_i * agreement_i * D_i * scale / B_i) = expectedScaled_i
//
// where:
// D_i = sum_{j != i} stake_j + 2*smoothing
// N_i = sum_{j != i} stake_j * report_j + smoothing
// B_i = report_i * N_i + (1-report_i) * (D_i-N_i)
// The lottery seed is Poseidon(disputeId, finalStateRoot, randomSeed). The
// contract is responsible for fixing randomSeed only after finalStateRoot is
// registered. Each coordinate draw is the low 32 bits of Poseidon(seed, i).
//
// Let rawThreshold_i = floor(expectedScaled_i * 2^LOTTERY_BITS / rhoTau).
// The circuit enforces:
// threshold_i = clamp(rawThreshold_i, gammaScaled, 2^LOTTERY_BITS-gammaScaled)
// win_i = 1 iff draw_i < threshold_i
// payout_i = win_i * rhoTau
// Therefore every public payout is exactly 0 or rhoTau.
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
    signal input rawThresholds[N];
    signal input thresholdRemainders[N];

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
    signal input gammaScaled;
    signal input randomSeed;

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
    component rawThresholdRange[N];
    component thresholdRemainderRange[N];
    component smoothingRange = Num2Bits(32);
    component kappaRange = Num2Bits(32);
    component scaleRange = Num2Bits(32);
    component rhoTauRange = Num2Bits(64);
    component rhoTauZero = IsZero();
    component rewardBudgetRange = Num2Bits(64);
    component rewardBudgetZero = IsZero();
    component gammaRange = Num2Bits(LOTTERY_BITS);
    component gammaZero = IsZero();
    component gammaUpperBound = LessThan(NBITS);

    smoothingRange.in <== smoothing;
    kappaRange.in <== kappa;
    scaleRange.in <== scale;
    rhoTauRange.in <== rhoTau;
    rhoTauZero.in <== rhoTau;
    rhoTauZero.out === 0;
    rewardBudgetRange.in <== rewardBudget;
    rewardBudgetZero.in <== rewardBudget;
    rewardBudgetZero.out === 0;
    gammaRange.in <== gammaScaled;
    gammaZero.in <== gammaScaled;
    gammaZero.out === 0;
    gammaUpperBound.in[0] <== gammaScaled;
    gammaUpperBound.in[1] <== 2 ** (LOTTERY_BITS - 1);
    gammaUpperBound.out === 1;

    var totalStakeExpr = 0;
    var totalOneStakeExpr = 0;
    for (var i = 0; i < N; i++) {
        reports[i] * (reports[i] - 1) === 0;
        stakeRange[i] = Num2Bits(32);
        stakeRange[i].in <== stakes[i];
        payoutRange[i] = Num2Bits(64);
        payoutRange[i].in <== payouts[i];
        recipientRange[i] = Num2Bits(160);
        recipientRange[i].in <== recipients[i];
        expectedRange[i] = Num2Bits(64);
        expectedRange[i].in <== expectedScaled[i];
        remainderRange[i] = Num2Bits(NBITS);
        remainderRange[i].in <== rewardRemainders[i];
        rawThresholdRange[i] = Num2Bits(NBITS);
        rawThresholdRange[i].in <== rawThresholds[i];
        thresholdRemainderRange[i] = Num2Bits(NBITS);
        thresholdRemainderRange[i].in <== thresholdRemainders[i];

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
    signal thresholdNumerator[N];
    signal thresholdRhs[N];
    signal thresholdRemLessThanRhoTau[N];
    signal gammaUpper;
    signal belowGamma[N];
    signal lowSelectedDelta[N];
    signal lowSelected[N];
    signal aboveUpper[N];
    signal thresholdDelta[N];
    signal threshold[N];
    signal expectedPayoutScaled[N];
    signal expectedPayoutScaledSum;
    signal expectedBudgetScaled;
    signal expectedBudgetOk;
    signal win[N];

    component remBound[N];
    component thresholdRemBound[N];
    component seedHash = Poseidon(3);
    component drawHash[N];
    component drawBits[N];
    component lotteryBound[N];
    component belowGammaCmp[N];
    component aboveUpperCmp[N];
    component expectedBudgetBound = LessThan(NBITS);

    seedHash.inputs[0] <== disputeId;
    seedHash.inputs[1] <== finalStateRoot;
    seedHash.inputs[2] <== randomSeed;
    seed <== seedHash.out;

    gammaUpper <== (2 ** LOTTERY_BITS) - gammaScaled;
    var expectedPayoutScaledSumExpr = 0;
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

        thresholdNumerator[i] <== expectedScaled[i] * (2 ** LOTTERY_BITS);
        thresholdRhs[i] <== rawThresholds[i] * rhoTau + thresholdRemainders[i];
        thresholdNumerator[i] === thresholdRhs[i];

        thresholdRemBound[i] = LessThan(NBITS);
        thresholdRemBound[i].in[0] <== thresholdRemainders[i];
        thresholdRemBound[i].in[1] <== rhoTau;
        thresholdRemLessThanRhoTau[i] <== thresholdRemBound[i].out;
        thresholdRemLessThanRhoTau[i] === 1;

        belowGammaCmp[i] = LessThan(NBITS);
        belowGammaCmp[i].in[0] <== rawThresholds[i];
        belowGammaCmp[i].in[1] <== gammaScaled;
        belowGamma[i] <== belowGammaCmp[i].out;
        lowSelectedDelta[i] <== belowGamma[i] * (gammaScaled - rawThresholds[i]);
        lowSelected[i] <== rawThresholds[i] + lowSelectedDelta[i];

        aboveUpperCmp[i] = LessThan(NBITS);
        aboveUpperCmp[i].in[0] <== gammaUpper;
        aboveUpperCmp[i].in[1] <== lowSelected[i];
        aboveUpper[i] <== aboveUpperCmp[i].out;
        thresholdDelta[i] <== aboveUpper[i] * (gammaUpper - lowSelected[i]);
        threshold[i] <== lowSelected[i] + thresholdDelta[i];

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

        lotteryBound[i] = LessThan(NBITS);
        lotteryBound[i].in[0] <== draw[i];
        lotteryBound[i].in[1] <== threshold[i];
        win[i] <== lotteryBound[i].out;

        payouts[i] === win[i] * rhoTau;
        expectedPayoutScaled[i] <== threshold[i] * rhoTau;
        expectedPayoutScaledSumExpr += expectedPayoutScaled[i];
    }
    expectedPayoutScaledSum <== expectedPayoutScaledSumExpr;
    expectedBudgetScaled <== rewardBudget * (2 ** LOTTERY_BITS);
    expectedBudgetBound.in[0] <== expectedPayoutScaledSum;
    expectedBudgetBound.in[1] <== expectedBudgetScaled + 1;
    expectedBudgetOk <== expectedBudgetBound.out;
    expectedBudgetOk === 1;
}

component main { public [payouts, recipients, stakes, smoothing, kappa, scale, rhoTau, disputeId, finalStateRoot, rewardBudget, gammaScaled, randomSeed] } = RewardCheck(8, 3, 128, 32);
