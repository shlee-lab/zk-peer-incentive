pragma circom 2.1.6;

// Minimal local bit decomposition gadget.
// Inputs must be known to fit in n bits.
template Num2Bits(n) {
    signal input in;
    signal output out[n];

    var lc = 0;
    var bitValue = 1;
    for (var i = 0; i < n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] - 1) === 0;
        lc += out[i] * bitValue;
        bitValue *= 2;
    }
    lc === in;
}

// Returns 1 when in[0] < in[1].
// Both inputs must fit in n bits.
template LessThan(n) {
    signal input in[2];
    signal output out;

    component bits = Num2Bits(n + 1);
    bits.in <== in[0] + (1 << n) - in[1];
    out <== 1 - bits.out[n];
}

// Reward-check circuit for binary reports and ring peer matching.
//
// Public:
// - stakes[i]
// - payoutScaled[i]
// - smoothing
// - kappa
// - scale
//
// Private witness:
// - reports[i]
// - remainders[i]
//
// This circuit verifies:
// floor(kappa * stake_i * agreement_i * D_i * scale / B_i) = payoutScaled_i
//
// where:
// D_i = sum_{j != i} stake_j + 2*smoothing
// N_i = sum_{j != i} stake_j * report_j + smoothing
// B_i = report_i * N_i + (1-report_i) * (D_i-N_i)
template RewardCheck(N, NBITS) {
    signal input reports[N];
    signal input remainders[N];

    signal input stakes[N];
    signal input payoutScaled[N];
    signal input smoothing;
    signal input kappa;
    signal input scale;

    signal totalStake;
    signal totalOneStake;

    var totalStakeExpr = 0;
    var totalOneStakeExpr = 0;
    for (var i = 0; i < N; i++) {
        reports[i] * (reports[i] - 1) === 0;
        totalStakeExpr += stakes[i];
        totalOneStakeExpr += stakes[i] * reports[i];
    }
    totalStake <== totalStakeExpr;
    totalOneStake <== totalOneStakeExpr;

    signal D[N];
    signal NOne[N];
    signal B[N];
    signal peerDiff[N];
    signal agreement[N];
    signal t1[N];
    signal t2[N];
    signal t3[N];
    signal numerator[N];
    signal rhs[N];
    signal remLessThanDenom[N];

    component remBound[N];

    for (var i = 0; i < N; i++) {
        D[i] <== totalStake - stakes[i] + 2 * smoothing;
        NOne[i] <== totalOneStake - stakes[i] * reports[i] + smoothing;
        B[i] <== reports[i] * NOne[i] + (1 - reports[i]) * (D[i] - NOne[i]);

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

        rhs[i] <== payoutScaled[i] * B[i] + remainders[i];
        numerator[i] === rhs[i];

        remBound[i] = LessThan(NBITS);
        remBound[i].in[0] <== remainders[i];
        remBound[i].in[1] <== B[i];
        remLessThanDenom[i] <== remBound[i].out;
        remLessThanDenom[i] === 1;
    }
}

component main { public [stakes, payoutScaled, smoothing, kappa, scale] } = RewardCheck(8, 128);
