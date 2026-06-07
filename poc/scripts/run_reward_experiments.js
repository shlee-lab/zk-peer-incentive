"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const {
  buildFinalState,
  computeRewardDivisionWitness,
  poseidonHash,
} = require("../reference/reward_model");

const FIELD_PRIME =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const LOTTERY_BITS = 32;
const LOTTERY_SCALE = 1n << BigInt(LOTTERY_BITS);
const N = 8;
const REPO_ROOT = path.resolve(__dirname, "../..");
const OUT_DIR = path.join(REPO_ROOT, "experiments/reward-evaluation");
const DATA_DIR = path.join(OUT_DIR, "data");

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
}

function recipientAddresses() {
  return [
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
    "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
    "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
    "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
  ].map((address) => BigInt(address));
}

function lowBits(value, bits) {
  return BigInt(value) & ((1n << BigInt(bits)) - 1n);
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

function median(values) {
  const sorted = [...values].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  return sorted[Math.floor(sorted.length / 2)];
}

function baseInputs(profile) {
  return {
    reports: profile.reports,
    stakes: profile.stakes,
    peerIndices: Array.from({ length: N }, (_, i) => (i + 1) % N),
    maciStateIndices: Array.from({ length: N }, (_, i) => BigInt(i + 1)),
    nonces: Array.from({ length: N }, (_, i) => fieldElement(`experiment nonce ${profile.name} ${i}`)),
    voterIds: Array.from({ length: N }, (_, i) => fieldElement(`experiment voter ${profile.name} ${i}`)),
    recipients: recipientAddresses(),
    disputeId: 78n,
    scale: 1_000n,
    lotteryBits: LOTTERY_BITS,
  };
}

async function lotteryFromExpected({ nonces, disputeId, finalStateRoot, randomness, expectedScaled, rhoTau }) {
  const seed = await poseidonHash([
    ...nonces,
    disputeId,
    finalStateRoot,
    randomness,
  ]);
  let totalPayout = 0n;
  let winnerCount = 0;
  const payouts = [];
  for (let i = 0; i < expectedScaled.length; i += 1) {
    const drawHash = await poseidonHash([seed, BigInt(i)]);
    const draw = lowBits(drawHash, LOTTERY_BITS);
    const win = draw * rhoTau < expectedScaled[i] * LOTTERY_SCALE;
    const payout = win ? rhoTau : 0n;
    payouts.push(payout);
    totalPayout += payout;
    winnerCount += win ? 1 : 0;
  }
  return { payouts, totalPayout, winnerCount };
}

async function runSweep(profiles) {
  const rows = [];
  const smoothings = [1n, 2n, 5n, 10n];
  const kappas = [25n, 50n, 100n, 150n];
  const rhoTaus = [1_000_000n, 3_000_000n, 10_000_000n];
  const trials = 128;

  for (const profile of profiles) {
    const common = baseInputs(profile);
    const finalState = await buildFinalState(common);
    for (const smoothing of smoothings) {
      for (const kappa of kappas) {
        const witness = computeRewardDivisionWitness({
          ...common,
          smoothing,
          kappa,
        });
        const expectedScaled = witness.map((reward) => reward.scaled);
        const totalExpected = expectedScaled.reduce((acc, value) => acc + value, 0n);
        const maxExpected = expectedScaled.reduce((acc, value) => (value > acc ? value : acc), 0n);

        for (const rhoTau of rhoTaus) {
          const valid = maxExpected <= rhoTau;
          let empiricalTotal = 0n;
          let empiricalWinners = 0;
          if (valid) {
            for (let trial = 0; trial < trials; trial += 1) {
              const result = await lotteryFromExpected({
                nonces: common.nonces,
                disputeId: common.disputeId,
                finalStateRoot: finalState.finalStateRoot,
                randomness: fieldElement(`sweep ${profile.name} ${smoothing} ${kappa} ${rhoTau} ${trial}`),
                expectedScaled,
                rhoTau,
              });
              empiricalTotal += result.totalPayout;
              empiricalWinners += result.winnerCount;
            }
          }

          rows.push({
            profile: profile.name,
            smoothing: smoothing.toString(),
            kappa: kappa.toString(),
            rhoTau: rhoTau.toString(),
            trials: valid ? trials : 0,
            valid,
            totalExpected: totalExpected.toString(),
            maxExpected: maxExpected.toString(),
            expectedWinners: decimal(totalExpected, rhoTau, 6),
            empiricalMeanPayout: valid ? decimal(empiricalTotal, BigInt(trials), 2) : "",
            empiricalMeanWinners: valid ? (empiricalWinners / trials).toFixed(4) : "",
            relativeError:
              valid && totalExpected > 0n
                ? `${Math.abs(Number(decimal(empiricalTotal, BigInt(trials), 6)) - Number(totalExpected)) / Number(totalExpected)}`
                : "",
          });
        }
      }
    }
  }
  return rows;
}

async function runLotteryTrials(profile) {
  const common = baseInputs(profile);
  const finalState = await buildFinalState(common);
  const smoothing = 1n;
  const kappa = 100n;
  const rhoTau = 3_000_000n;
  const witness = computeRewardDivisionWitness({
    ...common,
    smoothing,
    kappa,
  });
  const expectedScaled = witness.map((reward) => reward.scaled);
  const totalExpected = expectedScaled.reduce((acc, value) => acc + value, 0n);
  const rows = [];
  let cumulativePayout = 0n;
  let cumulativeWinners = 0;
  const trials = 512;

  for (let trial = 0; trial < trials; trial += 1) {
    const result = await lotteryFromExpected({
      nonces: common.nonces,
      disputeId: common.disputeId,
      finalStateRoot: finalState.finalStateRoot,
      randomness: fieldElement(`lottery trace ${profile.name} ${trial}`),
      expectedScaled,
      rhoTau,
    });
    cumulativePayout += result.totalPayout;
    cumulativeWinners += result.winnerCount;
    rows.push({
      trial: trial + 1,
      totalPayout: result.totalPayout.toString(),
      winnerCount: result.winnerCount,
      cumulativeMeanPayout: decimal(cumulativePayout, BigInt(trial + 1), 2),
      cumulativeMeanWinners: (cumulativeWinners / (trial + 1)).toFixed(4),
      theoreticalExpectedPayout: totalExpected.toString(),
      theoreticalExpectedWinners: decimal(totalExpected, rhoTau, 6),
    });
  }
  return rows;
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
    };
    const witness = computeRewardDivisionWitness(inputs);
    const expected = witness.map((reward) => reward.scaled);
    const totalStake = stakes.reduce((acc, value) => acc + value, 0n);
    const totalExpected = expected.reduce((acc, value) => acc + value, 0n);
    const nonDominantAverage = (totalExpected - expected[dominantIndex]) / BigInt(N - 1);
    rows.push({
      dominantStakeMultiplier: multiplier.toString(),
      dominantVoterIndex: dominantIndex,
      dominantStakeShare: decimal(stakes[dominantIndex], totalStake, 6),
      dominantExpectedReward: expected[dominantIndex].toString(),
      nonDominantAverageExpectedReward: nonDominantAverage.toString(),
      medianExpectedReward: median(expected).toString(),
      totalExpectedReward: totalExpected.toString(),
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
          totalExpectedReward: expected.reduce((acc, value) => acc + value, 0n).toString(),
          minExpectedReward: expected.reduce((acc, value) => (value < acc ? value : acc), expected[0]).toString(),
          medianExpectedReward: median(expected).toString(),
          maxExpectedReward: expected.reduce((acc, value) => (value > acc ? value : acc), 0n).toString(),
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
    { metric: "private_inputs", value: 80 },
    { metric: "constraints", value: 23881 },
    { metric: "lottery_bits", value: LOTTERY_BITS },
  ]);
}

async function main() {
  const profiles = [
    {
      name: "maci_anvil_reports",
      reports: [1, 0, 1, 1, 0, 0, 1, 0],
      stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    },
    {
      name: "alternating",
      reports: [1, 0, 1, 0, 1, 0, 1, 0],
      stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    },
    {
      name: "one_sided",
      reports: [1, 1, 1, 1, 1, 1, 1, 0],
      stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    },
    {
      name: "consensus",
      reports: [1, 1, 1, 1, 1, 1, 1, 1],
      stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    },
  ];

  fs.mkdirSync(DATA_DIR, { recursive: true });
  const sweepRows = await runSweep(profiles);
  const lotteryRows = await runLotteryTrials(profiles[0]);
  const concentrationRows = runStakeConcentration(profiles[0]);
  const rewardRows = runRewardTable(profiles);

  writeCsv(path.join(DATA_DIR, "parameter_sweep.csv"), sweepRows);
  writeCsv(path.join(DATA_DIR, "lottery_trials.csv"), lotteryRows);
  writeCsv(path.join(DATA_DIR, "stake_concentration.csv"), concentrationRows);
  writeCsv(path.join(DATA_DIR, "reward_sensitivity.csv"), rewardRows);
  writeProofShape();
  writeJson(path.join(DATA_DIR, "experiment_manifest.json"), {
    generatedAt: new Date().toISOString(),
    voters: N,
    lotteryBits: LOTTERY_BITS,
    sweepRows: sweepRows.length,
    lotteryTrials: lotteryRows.length,
    profiles: profiles.map((profile) => ({
      name: profile.name,
      reports: profile.reports,
      stakes: profile.stakes.map((stake) => stake.toString()),
    })),
    notes: [
      "Lottery trials intentionally sample many public randomness values to evaluate distribution, not to select a production seed.",
      "Circuit and contract remain fixed at N=8 for this PoC.",
    ],
  });

  console.log(`Wrote reward experiment data to ${DATA_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
