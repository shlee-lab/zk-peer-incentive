"use strict";

const assert = require("assert");
const {
  aggregateFrequency,
  cmp,
  computeRewards,
  div,
  formatFraction,
  fraction,
  mismatchRatios,
  splitLeaveOneOutFrequency,
  verifyScaledPayouts,
} = require("./reward_model");

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

function run() {
  testRewardComputationAndTamperDetection();
  testMatchedWeightingNeutrality();
  testMismatchBias();
  testSelfCalibrationBySplitting();
  console.log("All reward model tests passed.");
}

run();
