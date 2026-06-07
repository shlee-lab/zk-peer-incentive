pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// Reward-check circuit for binary reports, ring peer matching, lottery payouts,
// and MACI reward-sidecar state root binding.
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
// - disputeId (used as pollId for the MACI sidecar integration)
// - finalStateRoot (the reward sidecar root)
// - randomness (public draw entropy registered after the final reward state)
// - rhoTau
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
//
// The expected reward is:
// floor(kappa * stake_i * agreement_i * D_i * scale / B_i) = expectedScaled_i
//
// where:
// D_i = sum_{j != i} stake_j + 2*smoothing
// N_i = sum_{j != i} stake_j * report_j + smoothing
// B_i = report_i * N_i + (1-report_i) * (D_i-N_i)
//
// Each reward sidecar leaf is:
// Poseidon(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i, recipient_i).
// The circuit privately opens nonce_i and checks:
// nonceCommitment_i = Poseidon(nonce_i, 0).
// It then verifies a fixed-position Merkle path for every voter and requires each
// path to end at finalStateRoot.
//
// The seed is Poseidon(nonces..., disputeId, finalStateRoot, randomness). For each
// voter, draw_i is the low LOTTERY_BITS bits of Poseidon(seed, i), and the public
// payout is rhoTau iff draw_i * rhoTau < expectedScaled_i * 2^LOTTERY_BITS.
template RewardCheck(N, DEPTH, NBITS, LOTTERY_BITS) {
    signal input reports[N];
    signal input nonces[N];
    signal input maciStateIndices[N];
    signal input voterIds[N];
    signal input nonceCommitments[N];
    signal input merklePathElements[N][DEPTH];
    signal input expectedScaled[N];
    signal input rewardRemainders[N];

    signal input payouts[N];
    signal input recipients[N];
    signal input stakes[N];
    signal input smoothing;
    signal input kappa;
    signal input scale;
    signal input disputeId;
    signal input finalStateRoot;
    signal input randomness;
    signal input rhoTau;

    signal totalStake;
    signal totalOneStake;
    signal weightedReport[N];

    component seedHash = Poseidon(N + 3);
    component leafHash[N];
    component nonceCommitmentHash[N];
    component merkleHash[N][DEPTH];
    signal merkleNode[N][DEPTH + 1];

    component stakeRange[N];
    component payoutRange[N];
    component recipientRange[N];
    component expectedRange[N];
    component remainderRange[N];
    component smoothingRange = Num2Bits(32);
    component kappaRange = Num2Bits(32);
    component scaleRange = Num2Bits(32);
    component rhoTauRange = Num2Bits(64);

    smoothingRange.in <== smoothing;
    kappaRange.in <== kappa;
    scaleRange.in <== scale;
    rhoTauRange.in <== rhoTau;

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

        seedHash.inputs[i] <== nonces[i];

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
    seedHash.inputs[N] <== disputeId;
    seedHash.inputs[N + 1] <== finalStateRoot;
    seedHash.inputs[N + 2] <== randomness;

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
    signal expectedLeRhoTau[N];
    signal draw[N];
    signal drawTimesRhoTau[N];
    signal winThreshold[N];
    signal win[N];
    signal lotteryPayout[N];

    component remBound[N];
    component expectedBound[N];
    component drawHash[N];
    component drawBits[N];
    component winBound[N];

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

        expectedBound[i] = LessThan(NBITS);
        expectedBound[i].in[0] <== expectedScaled[i];
        expectedBound[i].in[1] <== rhoTau + 1;
        expectedLeRhoTau[i] <== expectedBound[i].out;
        expectedLeRhoTau[i] === 1;

        drawHash[i] = Poseidon(2);
        drawHash[i].inputs[0] <== seedHash.out;
        drawHash[i].inputs[1] <== i;

        drawBits[i] = Num2Bits_strict();
        drawBits[i].in <== drawHash[i].out;

        var drawExpr = 0;
        var bitValue = 1;
        for (var b = 0; b < LOTTERY_BITS; b++) {
            drawExpr += drawBits[i].out[b] * bitValue;
            bitValue *= 2;
        }
        draw[i] <== drawExpr;

        drawTimesRhoTau[i] <== draw[i] * rhoTau;
        winThreshold[i] <== expectedScaled[i] * (1 << LOTTERY_BITS);

        winBound[i] = LessThan(NBITS);
        winBound[i].in[0] <== drawTimesRhoTau[i];
        winBound[i].in[1] <== winThreshold[i];
        win[i] <== winBound[i].out;

        lotteryPayout[i] <== rhoTau * win[i];
        lotteryPayout[i] === payouts[i];
    }
}

component main { public [payouts, recipients, stakes, smoothing, kappa, scale, disputeId, finalStateRoot, randomness, rhoTau] } = RewardCheck(8, 3, 128, 32);
