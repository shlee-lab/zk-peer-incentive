pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// Reward-check circuit for binary reports, ring peer matching, and lottery payouts.
//
// Public signals are ordered with payouts first so RewardPool can compare
// publicSignals[0..N-1] directly with submitted claim amounts.
//
// Public:
// - payouts[i]
// - stakes[i]
// - smoothing
// - kappa
// - scale
// - disputeId
// - stateRoot
// - rhoTau
//
// Private witness:
// - reports[i]
// - nonces[i]
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
// A private seed is Poseidon(nonces..., disputeId, stateRoot). For each voter,
// draw_i is the low LOTTERY_BITS bits of Poseidon(seed, i), and the public
// payout is rhoTau iff draw_i * rhoTau < expectedScaled_i * 2^LOTTERY_BITS.
template RewardCheck(N, NBITS, LOTTERY_BITS) {
    signal input reports[N];
    signal input nonces[N];
    signal input expectedScaled[N];
    signal input rewardRemainders[N];

    signal input payouts[N];
    signal input stakes[N];
    signal input smoothing;
    signal input kappa;
    signal input scale;
    signal input disputeId;
    signal input stateRoot;
    signal input rhoTau;

    signal totalStake;
    signal totalOneStake;
    signal weightedReport[N];

    component seedHash = Poseidon(N + 2);

    var totalStakeExpr = 0;
    var totalOneStakeExpr = 0;
    for (var i = 0; i < N; i++) {
        reports[i] * (reports[i] - 1) === 0;
        seedHash.inputs[i] <== nonces[i];
        weightedReport[i] <== stakes[i] * reports[i];
        totalStakeExpr += stakes[i];
        totalOneStakeExpr += weightedReport[i];
    }
    seedHash.inputs[N] <== disputeId;
    seedHash.inputs[N + 1] <== stateRoot;

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

component main { public [payouts, stakes, smoothing, kappa, scale, disputeId, stateRoot, rhoTau] } = RewardCheck(8, 128, 32);
