"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const {
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
const LOTTERY_SAMPLE_COUNT = 64;

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
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
    const common = baseInputs(profile);
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

function writeProofShape() {
  writeCsv(path.join(DATA_DIR, "proof_shape.csv"), [
    { metric: "voters", value: 8 },
    { metric: "merkle_depth", value: 3 },
    { metric: "public_inputs", value: 31 },
    { metric: "private_inputs", value: 88 },
    { metric: "constraints", value: 23786 },
    { metric: "allocation_mode", value: "fixed_budget_lottery" },
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

  writeCsv(path.join(DATA_DIR, "parameter_sweep.csv"), sweepRows);
  writeCsv(path.join(DATA_DIR, "budget_allocation.csv"), allocationRows);
  writeCsv(path.join(DATA_DIR, "stake_concentration.csv"), concentrationRows);
  writeCsv(path.join(DATA_DIR, "reward_sensitivity.csv"), rewardRows);
  writeProofShape();
  writeJson(path.join(DATA_DIR, "experiment_manifest.json"), {
    generatedAt: new Date().toISOString(),
    voters: N,
    rewardBudget: DEFAULT_BUDGET.toString(),
    allocationMode: "fixed_total_budget",
    allocationBaseline: "scale",
    lotteryMode: "fixed-budget lottery; winners are sampled by Poseidon(seed, i), then payouts are normalized to rewardBudget",
    rhoTau: DEFAULT_RHO_TAU.toString(),
    lotterySamples: LOTTERY_SAMPLE_COUNT,
    stakeDesign: "uniform stakes for report-pattern experiments; stake effects are isolated in stake_concentration.csv",
    sweepRows: sweepRows.length,
    allocationRows: allocationRows.length,
    profiles: profiles.map((profile) => ({
      name: profile.name,
      reports: profile.reports,
      stakes: profile.stakes.map((stake) => stake.toString()),
    })),
    notes: [
      "Payouts are normalized to a fixed reward budget; total payout equals rewardBudget.",
      "Reward sensitivity is plotted as average max_i P_i / rewardBudget over deterministic lottery samples.",
      "A scale-sized allocation baseline keeps the denominator nonzero for all-zero-score profiles.",
      "Circuit and contract remain fixed at N=8 for this PoC.",
    ],
  });

  console.log(`Wrote reward experiment data to ${DATA_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
