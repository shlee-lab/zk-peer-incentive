"use strict";

const fs = require("fs");
const path = require("path");
const {
  computeFixedBudgetPayouts,
  computeRewardDivisionWitness,
} = require("../reference/reward_model");

const N = 8;
const REPO_ROOT = path.resolve(__dirname, "../..");
const OUT_DIR = path.join(REPO_ROOT, "experiments/reward-evaluation");
const DATA_DIR = path.join(OUT_DIR, "data");
const DEFAULT_STAKES = [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n];
const DEFAULT_BUDGET = 3_000_000n;

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

function runSweep(profiles) {
  const rows = [];
  const smoothings = [1n, 2n, 5n, 10n];
  const kappas = [25n, 50n, 100n, 150n];
  const rewardBudgets = [1_000_000n, 3_000_000n, 10_000_000n];

  for (const profile of profiles) {
    const common = baseInputs(profile);
    for (const smoothing of smoothings) {
      for (const kappa of kappas) {
        for (const rewardBudget of rewardBudgets) {
          const allocation = computeFixedBudgetPayouts({
            ...common,
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

function runBudgetAllocation(profile) {
  const inputs = {
    ...baseInputs(profile),
    smoothing: 1n,
    kappa: 100n,
    rewardBudget: DEFAULT_BUDGET,
  };
  const allocation = computeFixedBudgetPayouts(inputs);
  return allocation.payouts.map((payout, index) => ({
    voterIndex: index,
    report: profile.reports[index],
    stake: profile.stakes[index].toString(),
    expectedScore: allocation.rewardWitness[index].scaled.toString(),
    allocationScore: allocation.allocationScores[index].toString(),
    payout: payout.toString(),
    payoutShare: decimal(payout, DEFAULT_BUDGET, 6),
  }));
}

function runStakeConcentration(profile) {
  const rows = [];
  const multipliers = [1n, 2n, 4n, 8n, 16n, 32n, 64n];
  const dominantIndex = 2;
  for (const multiplier of multipliers) {
    const stakes = [...profile.stakes];
    stakes[dominantIndex] = profile.stakes[dominantIndex] * multiplier;
    const inputs = {
      ...baseInputs({ ...profile, stakes }),
      smoothing: 1n,
      kappa: 100n,
      rewardBudget: DEFAULT_BUDGET,
    };
    const allocation = computeFixedBudgetPayouts(inputs);
    const expected = allocation.rewardWitness.map((reward) => reward.scaled);
    const totalStake = stakes.reduce((acc, value) => acc + value, 0n);
    const totalScore = expected.reduce((acc, value) => acc + value, 0n);
    const totalPayout = allocation.payouts.reduce((acc, value) => acc + value, 0n);
    const nonDominantAveragePayout =
      (totalPayout - allocation.payouts[dominantIndex]) / BigInt(N - 1);
    rows.push({
      dominantStakeMultiplier: multiplier.toString(),
      dominantVoterIndex: dominantIndex,
      dominantStakeShare: decimal(stakes[dominantIndex], totalStake, 6),
      dominantExpectedScore: expected[dominantIndex].toString(),
      totalScore: totalScore.toString(),
      dominantPayout: allocation.payouts[dominantIndex].toString(),
      dominantPayoutShare: decimal(allocation.payouts[dominantIndex], DEFAULT_BUDGET, 6),
      nonDominantAveragePayout: nonDominantAveragePayout.toString(),
      medianPayout: median(allocation.payouts).toString(),
      totalPayout: totalPayout.toString(),
      totalStake: totalStake.toString(),
    });
  }
  return rows;
}

function runRewardTable(profiles) {
  const rows = [];
  for (const profile of profiles) {
    for (const smoothing of [1n, 5n, 10n]) {
      for (const kappa of [50n, 100n, 150n]) {
        const common = baseInputs(profile);
        const witness = computeRewardDivisionWitness({ ...common, smoothing, kappa });
        const expected = witness.map((reward) => reward.scaled);
        rows.push({
          profile: profile.name,
          smoothing: smoothing.toString(),
          kappa: kappa.toString(),
          totalScore: expected.reduce((acc, value) => acc + value, 0n).toString(),
          minScore: expected.reduce((acc, value) => (value < acc ? value : acc), expected[0]).toString(),
          medianScore: median(expected).toString(),
          maxScore: expected.reduce((acc, value) => (value > acc ? value : acc), 0n).toString(),
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
    { metric: "public_inputs", value: 30 },
    { metric: "private_inputs", value: 88 },
    { metric: "constraints", value: 17262 },
    { metric: "allocation_mode", value: "fixed_total_budget" },
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
  const sweepRows = runSweep(profiles);
  const allocationRows = runBudgetAllocation(profiles[0]);
  const concentrationRows = runStakeConcentration(profiles[0]);
  const rewardRows = runRewardTable(profiles);

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
    sweepRows: sweepRows.length,
    allocationRows: allocationRows.length,
    profiles: profiles.map((profile) => ({
      name: profile.name,
      reports: profile.reports,
      stakes: profile.stakes.map((stake) => stake.toString()),
    })),
    notes: [
      "Payouts are normalized to a fixed reward budget; total payout equals rewardBudget.",
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
