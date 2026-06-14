"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const {
  buildFinalState,
  computeBernoulliLotteryPayouts,
  computeFixedBudgetLotteryPayouts,
} = require("../reference/reward_model");

const N = 8;
const FIELD_PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const REPO_ROOT = path.resolve(__dirname, "../..");
const OUT_DIR = path.join(REPO_ROOT, "experiments/reward-evaluation");
const DATA_DIR = path.join(OUT_DIR, "data");
const DEFAULT_STAKES = Array.from({ length: N }, () => 10n);
const DEFAULT_BUDGET = 3_000_000n;
const DEFAULT_RHO_TAU = 3_000_000n;
const EXPOSURE_RHO_TAU = 25_000_000n;
const LOTTERY_SCALE = 1n << 32n;
const DEFAULT_PSI_SCALED = (10n * LOTTERY_SCALE) / 100n;
const LOTTERY_SAMPLE_COUNT = 64;
const LOTTERY_CI_SAMPLE_COUNT = Number(process.env.REWARD_LOTTERY_CI_SAMPLES || 512);
const FULL_MACI_E2E_FILE = path.join(DATA_DIR, "full_maci_reward_anvil_latest.json");
const DEFAULT_REWARD_GAS = {
  commitRandomSeed: 49_899,
  registerFinalState: 98_837,
  revealRandomSeed: 58_248,
  fundDispute: 47_418,
  finalizeRewards: 584_313,
  claim: 30_729,
};

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
}

function recipientValue(index) {
  return BigInt(`0x${crypto.createHash("sha256").update(`reward recipient ${index}`).digest("hex").slice(0, 40)}`);
}

function csvEscape(value) {
  const text = String(value);
  return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function writeCsv(file, rows) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (rows.length === 0) {
    fs.writeFileSync(file, "\n");
    return;
  }
  const headers = Object.keys(rows[0]);
  const lines = [
    headers.join(","),
    ...rows.map((row) => headers.map((header) => csvEscape(row[header])).join(",")),
  ];
  fs.writeFileSync(file, `${lines.join("\n")}\n`);
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function decimal(num, den, digits = 6) {
  if (den === 0n) return "";
  const scale = 10n ** BigInt(digits);
  const value = (num * scale) / den;
  const whole = value / scale;
  const frac = (value % scale).toString().padStart(digits, "0");
  return `${whole}.${frac}`;
}

function decimalFromNumber(value, digits = 6) {
  return value.toFixed(digits);
}

function decimalFixed(num, den, digits = 8) {
  num = BigInt(num);
  den = BigInt(den);
  const scale = 10n ** BigInt(digits);
  const value = (num * scale) / den;
  const whole = value / scale;
  const frac = (value % scale).toString().padStart(digits, "0");
  return `${whole}.${frac}`;
}

function readJsonIfExists(file) {
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function percentile(values, p) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = (sorted.length - 1) * p;
  const lo = Math.floor(index);
  const hi = Math.ceil(index);
  if (lo === hi) return sorted[lo];
  const weight = index - lo;
  return sorted[lo] * (1 - weight) + sorted[hi] * weight;
}

function mean(values) {
  if (values.length === 0) return 0;
  return values.reduce((acc, value) => acc + value, 0) / values.length;
}

function standardDeviation(values) {
  if (values.length < 2) return 0;
  const m = mean(values);
  const variance =
    values.reduce((acc, value) => acc + (value - m) * (value - m), 0) / (values.length - 1);
  return Math.sqrt(variance);
}

function median(values) {
  const sorted = [...values].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  return sorted[Math.floor(sorted.length / 2)];
}

function baseInputs(profile) {
  return {
    reports: profile.reports,
    stakes: profile.stakes,
    peerIndices: Array.from({ length: N }, (_, i) => (i + 1) % N),
    disputeId: 78n,
    scale: 1_000n,
    rhoTau: DEFAULT_RHO_TAU,
  };
}

function lotteryContext(profile, sampleIndex) {
  return {
    nonces: Array.from({ length: N }, (_, i) => fieldElement(`${profile.name} sample ${sampleIndex} nonce ${i}`)),
    stateRoot: fieldElement(`${profile.name} sample ${sampleIndex} state root`),
  };
}

function exposureStateInputs(profile, reports, nonces) {
  return {
    reports,
    nonces,
    stakes: profile.stakes,
    maciStateIndices: Array.from({ length: N }, (_, i) => BigInt(i + 1)),
    voterIds: Array.from({ length: N }, (_, i) => fieldElement(`${profile.name} exposure voter ${i}`)),
    recipients: Array.from({ length: N }, (_, i) => recipientValue(i)),
  };
}

async function exposureStateRoot(profile, reports, nonces) {
  const state = await buildFinalState(exposureStateInputs(profile, reports, nonces));
  return state.finalStateRoot;
}

function payoutStats(allocation) {
  const payouts = allocation.payouts;
  const totalPayout = payouts.reduce((acc, value) => acc + value, 0n);
  return {
    totalPayout,
    minPayout: payouts.reduce((acc, value) => (value < acc ? value : acc), payouts[0]),
    medianPayout: median(payouts),
    maxPayout: payouts.reduce((acc, value) => (value > acc ? value : acc), 0n),
    paidRecipientCount: payouts.filter((value) => value > 0n).length,
  };
}

async function runSweep(profiles) {
  const rows = [];
  const smoothings = [1n, 2n, 5n, 10n];
  const kappas = [0n, 1n, 5n, 10n, 25n, 50n, 100n];
  const rewardBudgets = [1_000_000n, 3_000_000n, 10_000_000n];

  for (const profile of profiles) {
    const common = { ...baseInputs(profile), rhoTau: EXPOSURE_RHO_TAU };
    for (const smoothing of smoothings) {
      for (const kappa of kappas) {
        for (const rewardBudget of rewardBudgets) {
          const allocation = await computeFixedBudgetLotteryPayouts({
            ...common,
            ...lotteryContext(profile, 0),
            smoothing,
            kappa,
            rewardBudget,
          });
          const expected = allocation.rewardWitness.map((reward) => reward.scaled);
          const stats = payoutStats(allocation);
          rows.push({
            profile: profile.name,
            smoothing: smoothing.toString(),
            kappa: kappa.toString(),
            rewardBudget: rewardBudget.toString(),
            totalScore: expected.reduce((acc, value) => acc + value, 0n).toString(),
            totalAllocationScore: allocation.totalAllocationScore.toString(),
            totalPayout: stats.totalPayout.toString(),
            minPayout: stats.minPayout.toString(),
            medianPayout: stats.medianPayout.toString(),
            maxPayout: stats.maxPayout.toString(),
            paidRecipientCount: stats.paidRecipientCount,
            reports: profile.reports.join(""),
          });
        }
      }
    }
  }
  return rows;
}

async function runBudgetAllocation(profile) {
  const inputs = {
    ...baseInputs(profile),
    ...lotteryContext(profile, 0),
    smoothing: 1n,
    kappa: 100n,
    rewardBudget: DEFAULT_BUDGET,
  };
  const allocation = await computeFixedBudgetLotteryPayouts(inputs);
  return allocation.payouts.map((payout, index) => ({
    voterIndex: index,
    report: profile.reports[index],
    peerIndex: inputs.peerIndices[index],
    peerReport: profile.reports[inputs.peerIndices[index]],
    peerMatch: profile.reports[index] === profile.reports[inputs.peerIndices[index]] ? 1 : 0,
    lotteryWin: allocation.wins[index].toString(),
    lotteryDraw: allocation.draws[index].toString(),
    stake: profile.stakes[index].toString(),
    expectedScore: allocation.rewardWitness[index].scaled.toString(),
    allocationScore: allocation.allocationScores[index].toString(),
    payout: payout.toString(),
    payoutShare: decimal(payout, DEFAULT_BUDGET, 6),
  }));
}

async function runStakeConcentration(profile) {
  const rows = [];
  const multipliers = [1n, 2n, 4n, 8n];
  const dominantIndex = 2;
  for (const multiplier of multipliers) {
    const stakes = [...profile.stakes];
    stakes[dominantIndex] = profile.stakes[dominantIndex] * multiplier;
    const inputs = {
      ...baseInputs({ ...profile, stakes }),
      smoothing: 1n,
      kappa: 100n,
      rhoTau: 25_000_000n,
      rewardBudget: DEFAULT_BUDGET,
    };
    let dominantPayoutSum = 0n;
    let othersAverageSum = 0n;
    let dominantWinCount = 0;
    let totalScore = 0n;
    let totalPayout = 0n;
    for (let sample = 0; sample < LOTTERY_SAMPLE_COUNT; sample += 1) {
      const allocation = await computeFixedBudgetLotteryPayouts({
        ...inputs,
        ...lotteryContext({ name: `${profile.name}-stake-${multiplier}` }, sample),
      });
      const expected = allocation.rewardWitness.map((reward) => reward.scaled);
      totalScore = expected.reduce((acc, value) => acc + value, 0n);
      totalPayout = allocation.payouts.reduce((acc, value) => acc + value, 0n);
      dominantPayoutSum += allocation.payouts[dominantIndex];
      othersAverageSum +=
        (totalPayout - allocation.payouts[dominantIndex]) / BigInt(N - 1);
      if (allocation.wins[dominantIndex] === 1n) dominantWinCount += 1;
    }
    const totalStake = stakes.reduce((acc, value) => acc + value, 0n);
    const sampleCount = BigInt(LOTTERY_SAMPLE_COUNT);
    const dominantPayout = dominantPayoutSum / sampleCount;
    const nonDominantAveragePayout = othersAverageSum / sampleCount;
    rows.push({
      dominantStakeMultiplier: multiplier.toString(),
      dominantVoterIndex: dominantIndex,
      dominantStakeShare: decimal(stakes[dominantIndex], totalStake, 6),
      dominantWinRate: decimalFromNumber(dominantWinCount / LOTTERY_SAMPLE_COUNT, 6),
      totalScore: totalScore.toString(),
      dominantPayout: dominantPayout.toString(),
      dominantPayoutShare: decimal(dominantPayout, DEFAULT_BUDGET, 6),
      nonDominantAveragePayout: nonDominantAveragePayout.toString(),
      totalPayout: totalPayout.toString(),
      totalStake: totalStake.toString(),
      samples: LOTTERY_SAMPLE_COUNT,
    });
  }
  return rows;
}

async function runRewardTable(profiles) {
  const rows = [];
  for (const profile of profiles) {
    for (const smoothing of [1n, 5n, 10n]) {
      for (const kappa of [0n, 1n, 5n, 10n, 25n, 50n, 100n]) {
        const common = baseInputs(profile);
        const peerMatches = profile.reports.map((report, index) =>
          report === profile.reports[common.peerIndices[index]] ? 1 : 0
        );
        let totalScore = 0n;
        let totalAllocationScore = 0n;
        let minScore = 0n;
        let medianScore = 0n;
        let maxScore = 0n;
        let avgPeerMatchPayoutShare = 0;
        let avgMaxPayoutShare = 0;
        let avgWinnerCount = 0;
        for (let sample = 0; sample < LOTTERY_SAMPLE_COUNT; sample += 1) {
          const allocation = await computeFixedBudgetLotteryPayouts({
            ...common,
            ...lotteryContext(profile, sample),
            smoothing,
            kappa,
            rewardBudget: DEFAULT_BUDGET,
          });
          const expected = allocation.rewardWitness.map((reward) => reward.scaled);
          const stats = payoutStats(allocation);
          const peerMatchPayout = allocation.payouts.reduce(
            (acc, payout, index) => acc + (peerMatches[index] === 1 ? payout : 0n),
            0n
          );
          totalScore = expected.reduce((acc, value) => acc + value, 0n);
          totalAllocationScore = allocation.totalAllocationScore;
          minScore = expected.reduce((acc, value) => (value < acc ? value : acc), expected[0]);
          medianScore = median(expected);
          maxScore = expected.reduce((acc, value) => (value > acc ? value : acc), 0n);
          avgPeerMatchPayoutShare += Number(peerMatchPayout) / Number(DEFAULT_BUDGET);
          avgMaxPayoutShare += Number(stats.maxPayout) / Number(DEFAULT_BUDGET);
          avgWinnerCount += allocation.wins.filter((win) => win === 1n).length;
        }
        avgPeerMatchPayoutShare /= LOTTERY_SAMPLE_COUNT;
        avgMaxPayoutShare /= LOTTERY_SAMPLE_COUNT;
        avgWinnerCount /= LOTTERY_SAMPLE_COUNT;
        rows.push({
          profile: profile.name,
          smoothing: smoothing.toString(),
          kappa: kappa.toString(),
          totalScore: totalScore.toString(),
          totalAllocationScore: totalAllocationScore.toString(),
          peerMatchCount: peerMatches.reduce((acc, value) => acc + value, 0),
          avgWinnerCount: decimalFromNumber(avgWinnerCount, 6),
          peerMatchPayoutShare: decimalFromNumber(avgPeerMatchPayoutShare, 6),
          maxPayoutShare: decimalFromNumber(avgMaxPayoutShare, 6),
          minScore: minScore.toString(),
          medianScore: medianScore.toString(),
          maxScore: maxScore.toString(),
          totalPayout: DEFAULT_BUDGET.toString(),
          samples: LOTTERY_SAMPLE_COUNT,
          reports: profile.reports.join(""),
        });
      }
    }
  }
  return rows;
}

async function runLotteryConfidence(profiles) {
  const rows = [];
  for (const profile of profiles) {
    for (const kappa of [0n, 1n, 5n, 10n, 25n, 50n, 100n]) {
      const common = baseInputs(profile);
      const peerMatches = profile.reports.map((report, index) =>
        report === profile.reports[common.peerIndices[index]] ? 1 : 0
      );
      const maxPayoutShares = [];
      const peerMatchPayoutShares = [];
      const winnerCounts = [];
      for (let sample = 0; sample < LOTTERY_CI_SAMPLE_COUNT; sample += 1) {
        const allocation = await computeFixedBudgetLotteryPayouts({
          ...common,
          ...lotteryContext({ name: `${profile.name}-ci` }, sample),
          smoothing: 1n,
          kappa,
          rewardBudget: DEFAULT_BUDGET,
        });
        const stats = payoutStats(allocation);
        const peerMatchPayout = allocation.payouts.reduce(
          (acc, payout, index) => acc + (peerMatches[index] === 1 ? payout : 0n),
          0n
        );
        maxPayoutShares.push(Number(stats.maxPayout) / Number(DEFAULT_BUDGET));
        peerMatchPayoutShares.push(Number(peerMatchPayout) / Number(DEFAULT_BUDGET));
        winnerCounts.push(allocation.wins.filter((win) => win === 1n).length);
      }
      rows.push({
        profile: profile.name,
        smoothing: "1",
        kappa: kappa.toString(),
        maxPayoutShareMean: decimalFromNumber(mean(maxPayoutShares), 6),
        maxPayoutShareStdErr: decimalFromNumber(
          standardDeviation(maxPayoutShares) / Math.sqrt(maxPayoutShares.length),
          6
        ),
        maxPayoutShareCiLow: decimalFromNumber(
          Math.max(
            0,
            mean(maxPayoutShares) -
              1.96 * standardDeviation(maxPayoutShares) / Math.sqrt(maxPayoutShares.length)
          ),
          6
        ),
        maxPayoutShareCiHigh: decimalFromNumber(
          Math.min(
            1,
            mean(maxPayoutShares) +
              1.96 * standardDeviation(maxPayoutShares) / Math.sqrt(maxPayoutShares.length)
          ),
          6
        ),
        maxPayoutShareP05: decimalFromNumber(percentile(maxPayoutShares, 0.05), 6),
        maxPayoutShareP50: decimalFromNumber(percentile(maxPayoutShares, 0.50), 6),
        maxPayoutShareP95: decimalFromNumber(percentile(maxPayoutShares, 0.95), 6),
        peerMatchPayoutShareMean: decimalFromNumber(mean(peerMatchPayoutShares), 6),
        peerMatchPayoutShareP05: decimalFromNumber(percentile(peerMatchPayoutShares, 0.05), 6),
        peerMatchPayoutShareP95: decimalFromNumber(percentile(peerMatchPayoutShares, 0.95), 6),
        winnerCountMean: decimalFromNumber(mean(winnerCounts), 6),
        winnerCountP05: decimalFromNumber(percentile(winnerCounts, 0.05), 6),
        winnerCountP95: decimalFromNumber(percentile(winnerCounts, 0.95), 6),
        samples: LOTTERY_CI_SAMPLE_COUNT,
        reports: profile.reports.join(""),
      });
    }
  }
  return rows;
}

function payoutDiffStats(originalPayouts, flippedPayouts) {
  const changed = [];
  let maxAbsPayoutChange = 0n;
  let totalAbsPayoutChange = 0n;
  for (let i = 0; i < originalPayouts.length; i += 1) {
    const diff = flippedPayouts[i] >= originalPayouts[i]
      ? flippedPayouts[i] - originalPayouts[i]
      : originalPayouts[i] - flippedPayouts[i];
    if (diff > 0n) changed.push(i);
    if (diff > maxAbsPayoutChange) maxAbsPayoutChange = diff;
    totalAbsPayoutChange += diff;
  }
  return {
    changed,
    maxAbsPayoutChange,
    totalAbsPayoutChange,
  };
}

function directRingAffectedIndices(peerIndices, voterIndex) {
  const affected = new Set([voterIndex]);
  peerIndices.forEach((peerIndex, index) => {
    if (peerIndex === voterIndex) affected.add(index);
  });
  return [...affected].sort((a, b) => a - b);
}

async function runExposureSanity(profiles) {
  const rows = [];
  for (const profile of profiles) {
    const common = baseInputs(profile);
    const context = lotteryContext({ name: `${profile.name}-exposure` }, 0);
    const baseStateRoot = await exposureStateRoot(profile, profile.reports, context.nonces);
    const modes = [
      {
        mode: "fixed_seed",
        description: "same nonces and same state root; isolates reward-rule payout changes",
        stateRootFor: async () => baseStateRoot,
      },
      {
        mode: "current_root_seed",
        description: "same nonces, recomputed finalRewardStateRoot; matches current seed binding",
        stateRootFor: async (reports) => exposureStateRoot(profile, reports, context.nonces),
      },
    ];

    for (const mode of modes) {
      const originalStateRoot = await mode.stateRootFor(profile.reports);
      const originalAllocation = await computeFixedBudgetLotteryPayouts({
        ...common,
        nonces: context.nonces,
        stateRoot: originalStateRoot,
        smoothing: 1n,
        kappa: 100n,
        rhoTau: EXPOSURE_RHO_TAU,
        rewardBudget: DEFAULT_BUDGET,
      });

      for (let voterIndex = 0; voterIndex < N; voterIndex += 1) {
        const flippedReports = [...profile.reports];
        flippedReports[voterIndex] = flippedReports[voterIndex] === 1 ? 0 : 1;
        const flippedStateRoot = await mode.stateRootFor(flippedReports);
        const flippedAllocation = await computeFixedBudgetLotteryPayouts({
          ...baseInputs({ ...profile, reports: flippedReports }),
          nonces: context.nonces,
          stateRoot: flippedStateRoot,
          smoothing: 1n,
          kappa: 100n,
          rhoTau: EXPOSURE_RHO_TAU,
          rewardBudget: DEFAULT_BUDGET,
        });
        const diff = payoutDiffStats(originalAllocation.payouts, flippedAllocation.payouts);
        rows.push({
          profile: profile.name,
          mode: mode.mode,
          voterIndex,
          originalReport: profile.reports[voterIndex],
          flippedReport: flippedReports[voterIndex],
          directRingAffectedIndices: directRingAffectedIndices(common.peerIndices, voterIndex).join(";"),
          changedPayoutCount: diff.changed.length,
          changedPayoutIndices: diff.changed.join(";"),
          maxAbsPayoutChange: diff.maxAbsPayoutChange.toString(),
          totalAbsPayoutChange: diff.totalAbsPayoutChange.toString(),
          description: mode.description,
        });
      }
    }
  }
  return rows;
}

async function runProbabilityExposure(profiles) {
  const rows = [];
  const lotteryConfigs = [
    { mode: "baseline", label: "baseline", psiScaled: 0n },
    { mode: "floor_adjusted", label: "psi=0.05", psiScaled: (5n * LOTTERY_SCALE) / 100n },
    { mode: "floor_adjusted", label: "psi=0.10", psiScaled: DEFAULT_PSI_SCALED },
    { mode: "floor_adjusted", label: "psi=0.20", psiScaled: (20n * LOTTERY_SCALE) / 100n },
    { mode: "floor_adjusted", label: "psi=0.30", psiScaled: (30n * LOTTERY_SCALE) / 100n },
  ];
  for (const profile of profiles) {
    const common = baseInputs(profile);
    const context = {
      stateRoot: fieldElement(`${profile.name} probability exposure root`),
      randomSeed: fieldElement(`${profile.name} probability exposure random seed`),
    };
    for (const { mode, label, psiScaled } of lotteryConfigs) {
      const original = await computeBernoulliLotteryPayouts({
        ...common,
        ...context,
        smoothing: 1n,
        kappa: 100n,
        lotteryMode: mode,
        psiScaled,
      });
      for (let voterIndex = 0; voterIndex < N; voterIndex += 1) {
        const flippedReports = [...profile.reports];
        flippedReports[voterIndex] = flippedReports[voterIndex] === 1 ? 0 : 1;
        const flipped = await computeBernoulliLotteryPayouts({
          ...baseInputs({ ...profile, reports: flippedReports }),
          rhoTau: EXPOSURE_RHO_TAU,
          ...context,
          smoothing: 1n,
          kappa: 100n,
          lotteryMode: mode,
          psiScaled,
        });
        const direct = new Set(directRingAffectedIndices(common.peerIndices, voterIndex));
        for (let coordinateIndex = 0; coordinateIndex < N; coordinateIndex += 1) {
          const q0 = original.thresholds[coordinateIndex];
          const q1 = flipped.thresholds[coordinateIndex];
          const delta = q1 >= q0 ? q1 - q0 : q0 - q1;
          rows.push({
            profile: profile.name,
            mode: label,
            lotteryMode: original.lotteryMode,
            psiScaled: psiScaled.toString(),
            rhoEff: original.rhoEff.toString(),
            voterIndex,
            coordinateIndex,
            directRingCoordinate: direct.has(coordinateIndex) ? 1 : 0,
            originalReport: profile.reports[voterIndex],
            flippedReport: flippedReports[voterIndex],
            originalQ: decimalFixed(q0, original.lotteryScale),
            flippedQ: decimalFixed(q1, flipped.lotteryScale),
            absDeltaQ: decimalFixed(delta, original.lotteryScale),
            deltaThreshold: delta.toString(),
          });
        }
      }
    }
  }
  return rows;
}

function writeE2EOverhead() {
  const latest = readJsonIfExists(FULL_MACI_E2E_FILE) || {};
  const proofTimes = latest.proofTimesMs || {};
  const rewardGas = latest.rewardGas || DEFAULT_REWARD_GAS;
  writeCsv(path.join(DATA_DIR, "gas_breakdown.csv"), [
    { operation: "commit", gas: rewardGas.commitRandomSeed || 0 },
    { operation: "register", gas: rewardGas.registerFinalState },
    { operation: "reveal", gas: rewardGas.revealRandomSeed || 0 },
    { operation: "fund", gas: rewardGas.fundDispute },
    { operation: "finalize", gas: rewardGas.finalizeRewards },
    { operation: "claim", gas: rewardGas.claim },
  ]);
  const rows = [
    {
      section: "proof_time",
      metric: "MACI proof phase",
      value: proofTimes.maci ? (proofTimes.maci / 1000).toFixed(3) : "",
      unit: "seconds",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "proof_time",
      metric: "Reward proof phase",
      value: proofTimes.reward ? (proofTimes.reward / 1000).toFixed(3) : "",
      unit: "seconds",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "reward_gas",
      metric: "Commit seed",
      value: rewardGas.commitRandomSeed || "",
      unit: "gas",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "reward_gas",
      metric: "Register root",
      value: rewardGas.registerFinalState,
      unit: "gas",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "reward_gas",
      metric: "Reveal seed",
      value: rewardGas.revealRandomSeed || "",
      unit: "gas",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "reward_gas",
      metric: "Fund pool",
      value: rewardGas.fundDispute,
      unit: "gas",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "reward_gas",
      metric: "Verify + finalize",
      value: rewardGas.finalizeRewards,
      unit: "gas",
      source: "full_maci_reward_anvil_latest",
    },
    {
      section: "reward_gas",
      metric: "Claim",
      value: rewardGas.claim,
      unit: "gas",
      source: "full_maci_reward_anvil_latest",
    },
  ];
  writeCsv(path.join(DATA_DIR, "e2e_overhead.csv"), rows);
}

function writeOperatingCostProjection() {
  const latest = readJsonIfExists(FULL_MACI_E2E_FILE) || {};
  const rewardGas = latest.rewardGas || DEFAULT_REWARD_GAS;
  const measuredN = 8;
  const perRecipientFinalizeGas = 22_000;
  const finalizeBaseGas = Math.max(
    0,
    Number(rewardGas.finalizeRewards) - perRecipientFinalizeGas * measuredN
  );
  const ethUsd = 3000;
  const networks = [
    { network: "Ethereum L1", gasPriceGwei: 20 },
    { network: "Arbitrum execution", gasPriceGwei: 0.1 },
  ];
  const voterCounts = [10, 100, 1000];
  const rows = [];
  for (const { network, gasPriceGwei } of networks) {
    for (const voters of voterCounts) {
      const finalizeGas = finalizeBaseGas + perRecipientFinalizeGas * voters;
      const seedGas = Number(rewardGas.commitRandomSeed || 0) + Number(rewardGas.revealRandomSeed || 0);
      const adminGas =
        seedGas + Number(rewardGas.registerFinalState) + Number(rewardGas.fundDispute) + finalizeGas;
      const allClaimGas = Number(rewardGas.claim) * voters;
      const totalGas = adminGas + allClaimGas;
      const ethCost = totalGas * gasPriceGwei * 1e-9;
      rows.push({
        network,
        voters,
        gasPriceGwei,
        ethUsd,
        registerGas: rewardGas.registerFinalState,
        commitSeedGas: rewardGas.commitRandomSeed || 0,
        revealSeedGas: rewardGas.revealRandomSeed || 0,
        fundGas: rewardGas.fundDispute,
        finalizeBaseGas,
        perRecipientFinalizeGas,
        finalizeGas,
        claimGasPerRecipient: rewardGas.claim,
        allClaimGas,
        adminGas,
        totalOperationalGas: totalGas,
        totalEth: ethCost.toFixed(8),
        totalUsd: (ethCost * ethUsd).toFixed(2),
        note: "deployment excluded; Arbitrum row is execution-gas-only illustrative model",
      });
    }
  }
  writeCsv(path.join(DATA_DIR, "operating_cost_projection.csv"), rows);
}

function writeProofShape() {
  writeCsv(path.join(DATA_DIR, "proof_shape.csv"), [
    { metric: "voters", value: 8 },
    { metric: "merkle_depth", value: 3 },
    { metric: "public_inputs", value: 34 },
    { metric: "private_inputs", value: 112 },
    { metric: "constraints", value: 30164 },
    { metric: "allocation_mode", value: "baseline_or_floor_adjusted_bernoulli_lottery" },
    { metric: "seed_mode", value: "external_commit_reveal_seed" },
  ]);
}

async function main() {
  const profiles = [
    {
      name: "maci_anvil_reports",
      reports: [1, 0, 1, 1, 0, 0, 1, 0],
      stakes: DEFAULT_STAKES,
    },
    {
      name: "alternating",
      reports: [1, 0, 1, 0, 1, 0, 1, 0],
      stakes: DEFAULT_STAKES,
    },
    {
      name: "one_sided",
      reports: [1, 1, 1, 1, 1, 1, 1, 0],
      stakes: DEFAULT_STAKES,
    },
    {
      name: "consensus",
      reports: [1, 1, 1, 1, 1, 1, 1, 1],
      stakes: DEFAULT_STAKES,
    },
  ];

  fs.mkdirSync(DATA_DIR, { recursive: true });
  const sweepRows = await runSweep(profiles);
  const allocationRows = await runBudgetAllocation(profiles[0]);
  const concentrationRows = await runStakeConcentration(profiles[0]);
  const rewardRows = await runRewardTable(profiles);
  const lotteryConfidenceRows = await runLotteryConfidence(profiles);
  const exposureRows = await runExposureSanity(profiles);
  const probabilityExposureRows = await runProbabilityExposure(profiles);

  writeCsv(path.join(DATA_DIR, "parameter_sweep.csv"), sweepRows);
  writeCsv(path.join(DATA_DIR, "budget_allocation.csv"), allocationRows);
  writeCsv(path.join(DATA_DIR, "stake_concentration.csv"), concentrationRows);
  writeCsv(path.join(DATA_DIR, "reward_sensitivity.csv"), rewardRows);
  writeCsv(path.join(DATA_DIR, "lottery_confidence.csv"), lotteryConfidenceRows);
  writeCsv(path.join(DATA_DIR, "exposure_sanity.csv"), exposureRows);
  writeCsv(path.join(DATA_DIR, "exposure_probability_sanity.csv"), probabilityExposureRows);
  writeE2EOverhead();
  writeOperatingCostProjection();
  writeProofShape();
  writeJson(path.join(DATA_DIR, "experiment_manifest.json"), {
    generatedAt: new Date().toISOString(),
    voters: N,
    rewardBudget: (BigInt(N) * DEFAULT_RHO_TAU).toString(),
    allocationMode: "coordinate_bernoulli_lottery",
    fixedBudgetBaseline: DEFAULT_BUDGET.toString(),
    allocationBaseline: "scale",
    lotteryMode: "current circuit supports baseline q=x/rho and floor_adjusted q=psi+(1-2psi)x/rho",
    rhoTau: DEFAULT_RHO_TAU.toString(),
    defaultPsiScaled: DEFAULT_PSI_SCALED.toString(),
    defaultRhoEff: (((LOTTERY_SCALE - 2n * DEFAULT_PSI_SCALED) * DEFAULT_RHO_TAU) / LOTTERY_SCALE).toString(),
    lotterySamples: LOTTERY_SAMPLE_COUNT,
    lotteryConfidenceSamples: LOTTERY_CI_SAMPLE_COUNT,
    exposureRows: exposureRows.length,
    exposureMaxChangedPayoutCount: Math.max(...exposureRows.map((row) => row.changedPayoutCount)),
    probabilityExposureRows: probabilityExposureRows.length,
    exposureRhoTau: EXPOSURE_RHO_TAU.toString(),
    stakeDesign: "uniform stakes for report-pattern experiments; stake effects are isolated in stake_concentration.csv",
    sweepRows: sweepRows.length,
    allocationRows: allocationRows.length,
    profiles: profiles.map((profile) => ({
      name: profile.name,
      reports: profile.reports,
      stakes: profile.stakes.map((stake) => stake.toString()),
    })),
    notes: [
      "Current integrated payouts are Bernoulli: each public payout is either 0 or rhoTau.",
      "Floor-adjusted mode makes q_i = psi + (1-2*psi)*x_i/rhoTau; baseline mode uses q_i = x_i/rhoTau.",
      "Total Bernoulli payout is a random variable; the pool funds N*rhoTau maximum exposure.",
      "Fixed-budget allocation files remain as a legacy exact-budget comparison baseline.",
      "Reward sensitivity is plotted as average max_i P_i / baseline budget over deterministic lottery samples for the legacy comparison figure.",
      "Lottery confidence data reports 5th, 50th, and 95th percentile bands over deterministic lottery samples.",
      "A scale-sized allocation baseline keeps the denominator nonzero for all-zero-score profiles.",
      "Current lottery seed uses Poseidon(poll id, final reward root, external randomSeed).",
      "Exposure sanity flips one report at a time; probability exposure records q_j movement rather than only final sampled payouts.",
      "Probability exposure sanity records coordinate-wise q_j changes under the Bernoulli reward rule.",
      "The integrated MACI/reward flow remains fixed at N=8; capacity-utilization data is generated separately with N_max=64.",
    ],
  });

  console.log(`Wrote reward experiment data to ${DATA_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
