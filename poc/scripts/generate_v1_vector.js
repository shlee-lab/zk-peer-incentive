"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { computeLotteryPayouts, computeRewardDivisionWitness } = require("../reference/reward_model");

const FIELD_PRIME =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
}

function bigintReplacer(_, value) {
  return typeof value === "bigint" ? value.toString() : value;
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, bigintReplacer, 2)}\n`);
}

function v1Inputs() {
  return {
    reports: [1, 1, 0, 1, 0, 0, 1, 0],
    stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    peerIndices: [1, 2, 3, 4, 5, 6, 7, 0],
    nonces: Array.from({ length: 8 }, (_, i) => fieldElement(`zk-peer-v1 nonce ${i}`)),
    disputeId: 77n,
    stateRoot: fieldElement("zk-peer-v1 unbound state root"),
    smoothing: 1n,
    kappa: 100n,
    scale: 1_000n,
    rhoTau: 3_000_000n,
    lotteryBits: 32,
  };
}

async function main() {
  const inputs = v1Inputs();
  const lottery = await computeLotteryPayouts(inputs);
  const rewardWitness = computeRewardDivisionWitness(inputs);
  const payouts = lottery.payouts.map((payout) => payout.toString());

  if (lottery.wins.every((win) => win === 0n)) {
    throw new Error("deterministic v1 vector produced no lottery winners");
  }

  const vector = {
    version: "v1",
    description: "Deterministic lottery reward proof vector. stateRoot is context only in v1.",
    inputs,
    seed: lottery.seed.toString(),
    lotteryScale: lottery.lotteryScale.toString(),
    expectedRewards: rewardWitness.map((reward) => reward.scaled.toString()),
    rewardRemainders: rewardWitness.map((reward) => reward.remainder.toString()),
    drawHashes: lottery.drawHashes.map((hash) => hash.toString()),
    draws: lottery.draws.map((draw) => draw.toString()),
    wins: lottery.wins.map((win) => win.toString()),
    payouts,
  };

  const circuitInput = {
    reports: inputs.reports,
    nonces: inputs.nonces,
    expectedScaled: vector.expectedRewards,
    rewardRemainders: vector.rewardRemainders,
    payouts,
    stakes: inputs.stakes,
    smoothing: inputs.smoothing,
    kappa: inputs.kappa,
    scale: inputs.scale,
    disputeId: inputs.disputeId,
    stateRoot: inputs.stateRoot,
    rhoTau: inputs.rhoTau,
  };

  writeJson(path.join(__dirname, "../vectors/v1/reward_lottery.json"), vector);
  writeJson(path.join(__dirname, "../artifacts/v1/input.json"), circuitInput);
  console.log("Wrote vectors/v1/reward_lottery.json");
  console.log("Wrote artifacts/v1/input.json");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
