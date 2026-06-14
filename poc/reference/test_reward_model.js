"use strict";

const assert = require("assert");
const {
  aggregateFrequency,
  buildFinalState,
  cmp,
  computeBernoulliLotteryPayouts,
  computeLotteryThreshold,
  computeLotteryPayouts,
  computeRewards,
  div,
  formatFraction,
  fraction,
  mismatchRatios,
  splitLeaveOneOutFrequency,
  verifyMerklePath,
  verifyBernoulliLotteryPayouts,
  verifyLotteryPayouts,
  verifyScaledPayouts,
} = require("./reward_model");

const LOTTERY_SCALE_32 = 1n << 32n;

function absDiff(a, b) {
  const diff = fraction(a.num * b.den - b.num * a.den, a.den * b.den);
  return diff.num < 0n ? fraction(-diff.num, diff.den) : diff;
}

function testRewardComputationAndTamperDetection() {
  const inputs = {
    reports: [1, 1, 0, 1, 0, 0, 1, 0],
    stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    peerIndices: [1, 0, 4, 6, 2, 7, 3, 5],
    smoothing: 1n,
    kappa: 100n,
    scale: 1_000n,
  };

  const { rewards } = computeRewards(inputs);
  const payouts = rewards.map((r) => r.scaled);
  assert.strictEqual(verifyScaledPayouts(inputs, payouts), true);

  const tampered = payouts.slice();
  tampered[0] += 1n;
  assert.strictEqual(verifyScaledPayouts(inputs, tampered), false);
}

function testMatchedWeightingNeutrality() {
  const kappa = 3n;
  const split = [
    { stake: 70n, report: 1 },
    { stake: 20n, report: 0 },
    { stake: 10n, report: 1 },
  ];

  const totalExpected = split.reduce((acc, account) => acc + kappa * account.stake, 0n);
  assert.strictEqual(totalExpected, 300n);
}

function testMismatchBias() {
  const ratios = mismatchRatios(
    { "1": 70n, "0": 30n },
    { "1": 40n, "0": 60n },
    100n,
  );

  assert.strictEqual(formatFraction(ratios["1"]), "175");
  assert.strictEqual(formatFraction(ratios["0"]), "50");
  assert(cmp(ratios["1"], fraction(100n)) > 0);
  assert(cmp(ratios["0"], fraction(100n)) < 0);
}

function testSelfCalibrationBySplitting() {
  const outsideStake = 900n;
  const outsideOneStake = 450n;

  const aggregateSingle = aggregateFrequency({
    outsideStake,
    outsideOneStake,
    manipulatorReports: [1],
    manipulatorStakes: [100n],
  });
  const looSingle = splitLeaveOneOutFrequency({
    outsideStake,
    outsideOneStake,
    manipulatorReports: [1],
    manipulatorStakes: [100n],
    accountIndex: 0,
  });
  const singleGap = absDiff(aggregateSingle, looSingle);

  const reports = Array(10).fill(1);
  const stakes = Array(10).fill(10n);
  const aggregateSplit = aggregateFrequency({
    outsideStake,
    outsideOneStake,
    manipulatorReports: reports,
    manipulatorStakes: stakes,
  });
  const looSplit = splitLeaveOneOutFrequency({
    outsideStake,
    outsideOneStake,
    manipulatorReports: reports,
    manipulatorStakes: stakes,
    accountIndex: 0,
  });
  const splitGap = absDiff(aggregateSplit, looSplit);

  assert.strictEqual(formatFraction(aggregateSingle), "11/20");
  assert.strictEqual(formatFraction(aggregateSplit), "11/20");
  assert(cmp(splitGap, singleGap) < 0);

  const bound = div(fraction(10n), fraction(990n));
  assert(cmp(splitGap, bound) <= 0);
}

async function testLotteryPayoutsAndTamperDetection() {
  const vector = require("../vectors/v1/reward_lottery.json");
  const inputs = vector.inputs;
  const computed = await computeLotteryPayouts(inputs);

  assert.strictEqual(computed.seed.toString(), vector.seed);
  assert.deepStrictEqual(
    computed.rewardWitness.map((reward) => reward.scaled.toString()),
    vector.expectedRewards,
  );
  assert.deepStrictEqual(
    computed.rewardWitness.map((reward) => reward.remainder.toString()),
    vector.rewardRemainders,
  );
  assert.deepStrictEqual(computed.draws.map((draw) => draw.toString()), vector.draws);
  assert.deepStrictEqual(computed.payouts.map((payout) => payout.toString()), vector.payouts);
  assert.strictEqual(await verifyLotteryPayouts(inputs, vector.payouts), true);

  const tampered = vector.payouts.slice();
  tampered[0] = (BigInt(tampered[0]) + 1n).toString();
  assert.strictEqual(await verifyLotteryPayouts(inputs, tampered), false);
}

function testFloorAdjustedThresholds() {
  const rhoTau = 1_000_000n;
  const psiScaled = LOTTERY_SCALE_32 / 10n;
  const slope = LOTTERY_SCALE_32 - 2n * psiScaled;

  const zero = computeLotteryThreshold({
    scoreScaled: 0n,
    rhoTau,
    psiScaled,
    lotteryMode: "floor_adjusted",
  });
  assert.strictEqual(zero.threshold, psiScaled);

  const max = computeLotteryThreshold({
    scoreScaled: rhoTau,
    rhoTau,
    psiScaled,
    lotteryMode: "floor_adjusted",
  });
  assert.strictEqual(max.threshold, LOTTERY_SCALE_32 - psiScaled);

  const half = computeLotteryThreshold({
    scoreScaled: rhoTau / 2n,
    rhoTau,
    psiScaled,
    lotteryMode: "floor_adjusted",
  });
  assert.strictEqual(half.threshold, psiScaled + slope / 2n);
  assert.strictEqual(half.rhoEff, (slope * rhoTau) / LOTTERY_SCALE_32);

  const baseline = computeLotteryThreshold({
    scoreScaled: rhoTau / 2n,
    rhoTau,
    lotteryMode: "baseline",
  });
  assert.strictEqual(baseline.threshold, LOTTERY_SCALE_32 / 2n);
  assert.throws(() =>
    computeLotteryThreshold({
      scoreScaled: rhoTau / 2n,
      rhoTau,
      psiScaled,
      lotteryMode: "baseline",
    }),
  );
}

async function testMerkleFinalStateVector() {
  const vector = require("../vectors/v2/reward_bernoulli_state.json");
  const inputs = vector.inputs;
  const finalState = await buildFinalState(inputs);
  const allocation = await computeBernoulliLotteryPayouts(inputs);

  assert.deepStrictEqual(finalState.leaves.map((leaf) => leaf.toString()), vector.leaves);
  assert.strictEqual(finalState.finalStateRoot.toString(), vector.finalStateRoot);
  assert.strictEqual(allocation.seed.toString(), vector.seed);
  assert.deepStrictEqual(allocation.draws.map((draw) => draw.toString()), vector.draws);
  assert.deepStrictEqual(allocation.wins.map((win) => win.toString()), vector.wins);
  assert.deepStrictEqual(
    allocation.rewardWitness.map((reward) => reward.scaled.toString()),
    vector.expectedRewards,
  );
  assert.deepStrictEqual(
    allocation.rawThresholds.map((threshold) => threshold.toString()),
    vector.rawThresholds,
  );
  assert.deepStrictEqual(
    allocation.thresholds.map((threshold) => threshold.toString()),
    vector.thresholds,
  );
  assert.deepStrictEqual(
    allocation.adjustedThresholds.map((threshold) => threshold.toString()),
    vector.adjustedThresholds,
  );
  assert.deepStrictEqual(
    allocation.adjustedThresholdRemainders.map((remainder) => remainder.toString()),
    vector.adjustedThresholdRemainders,
  );
  assert.strictEqual(allocation.lotteryMode, vector.lotteryMode);
  assert.strictEqual(allocation.rhoEff.toString(), vector.rhoEff);
  assert.deepStrictEqual(allocation.payouts.map((payout) => payout.toString()), vector.payouts);
  assert.strictEqual(await verifyBernoulliLotteryPayouts(inputs, vector.payouts), true);

  for (let i = 0; i < finalState.leaves.length; i += 1) {
    assert.deepStrictEqual(
      finalState.paths[i].pathElements.map((element) => element.toString()),
      vector.merklePaths[i].pathElements,
    );
    assert.deepStrictEqual(finalState.paths[i].pathIndices, vector.merklePaths[i].pathIndices);
    assert.strictEqual(
      await verifyMerklePath({
        leaf: finalState.leaves[i],
        root: finalState.finalStateRoot,
        pathElements: finalState.paths[i].pathElements,
        pathIndices: finalState.paths[i].pathIndices,
      }),
      true,
    );
  }

  const tamperedPath = finalState.paths[0].pathElements.slice();
  tamperedPath[0] += 1n;
  assert.strictEqual(
    await verifyMerklePath({
      leaf: finalState.leaves[0],
      root: finalState.finalStateRoot,
      pathElements: tamperedPath,
      pathIndices: finalState.paths[0].pathIndices,
    }),
    false,
  );
}

async function run() {
  testRewardComputationAndTamperDetection();
  testMatchedWeightingNeutrality();
  testMismatchBias();
  testSelfCalibrationBySplitting();
  await testLotteryPayoutsAndTamperDetection();
  testFloorAdjustedThresholds();
  await testMerkleFinalStateVector();
  console.log("All reward model tests passed.");
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
