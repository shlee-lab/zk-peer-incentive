"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const ethers = require("ethers");
const {
  buildFinalState,
  computeBernoulliLotteryPayouts,
} = require("../reference/reward_model");

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
  ];
}

function gammaScaled(numerator, denominator, bits = 32n) {
  return (BigInt(numerator) * (1n << bits)) / BigInt(denominator);
}

function randomSeedMaterial(disputeId, finalStateRoot) {
  const seedPreimage = fieldElement("zk-peer-v2 external lottery seed");
  const salt =
    "0x" + crypto.createHash("sha256").update("zk-peer-v2 external lottery salt").digest("hex");
  const seedCommitment = ethers.utils.solidityKeccak256(
    ["uint256", "bytes32"],
    [seedPreimage.toString(), salt],
  );
  const randomSeed =
    BigInt(ethers.utils.solidityKeccak256(
      ["uint256", "bytes32", "uint256", "uint256"],
      [seedPreimage.toString(), salt, disputeId.toString(), finalStateRoot.toString()],
    )) % FIELD_PRIME;
  return { seedPreimage, salt, seedCommitment, randomSeed };
}

function v2Inputs() {
  return {
    reports: [1, 1, 0, 1, 0, 0, 1, 0],
    stakes: [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n],
    peerIndices: [1, 2, 3, 4, 5, 6, 7, 0],
    maciStateIndices: Array.from({ length: 8 }, (_, i) => BigInt(i + 1)),
    nonces: Array.from({ length: 8 }, (_, i) => fieldElement(`zk-peer-v2 nonce ${i}`)),
    voterIds: Array.from({ length: 8 }, (_, i) => fieldElement(`zk-peer-v2 voter ${i}`)),
    recipients: recipientAddresses().map((address) => BigInt(address)),
    disputeId: 78n,
    smoothing: 1n,
    kappa: 100n,
    scale: 1_000n,
    rhoTau: 3_000_000n,
    rewardBudget: 24_000_000n,
    gammaScaled: gammaScaled(5n, 100n),
  };
}

async function main() {
  const inputs = v2Inputs();
  const finalState = await buildFinalState(inputs);
  const seed = randomSeedMaterial(inputs.disputeId, finalState.finalStateRoot);
  const sidecarInputs = { ...inputs, nonceCommitments: finalState.nonceCommitments };
  const rewardInputs = {
    ...sidecarInputs,
    stateRoot: finalState.finalStateRoot,
    randomSeed: seed.randomSeed,
  };
  const allocation = await computeBernoulliLotteryPayouts(rewardInputs);
  const rewardWitness = allocation.rewardWitness;
  const payouts = allocation.payouts.map((payout) => payout.toString());

  if (!allocation.payouts.every((payout) => payout === 0n || payout === inputs.rhoTau)) {
    throw new Error("deterministic v2 vector has a non-Bernoulli payout");
  }

  const vector = {
    version: "v2",
    description: "Coordinate-wise Bernoulli lottery reward vector bound to a MACI reward sidecar state root.",
    inputs: rewardInputs,
    seedPreimage: seed.seedPreimage.toString(),
    seedSalt: seed.salt,
    seedCommitment: seed.seedCommitment,
    randomSeed: seed.randomSeed.toString(),
    nonceCommitments: finalState.nonceCommitments.map((commitment) => commitment.toString()),
    leaves: finalState.leaves.map((leaf) => leaf.toString()),
    merklePaths: finalState.paths.map((pathData) => ({
      pathElements: pathData.pathElements.map((element) => element.toString()),
      pathIndices: pathData.pathIndices,
    })),
    finalStateRoot: finalState.finalStateRoot.toString(),
    seed: allocation.seed.toString(),
    lotteryBits: allocation.lotteryBits,
    lotteryScale: allocation.lotteryScale.toString(),
    rhoTau: allocation.rhoTau.toString(),
    gammaScaled: allocation.gammaScaled.toString(),
    upperThreshold: allocation.upperThreshold.toString(),
    drawHashes: allocation.drawHashes.map((hash) => hash.toString()),
    draws: allocation.draws.map((draw) => draw.toString()),
    wins: allocation.wins.map((win) => win.toString()),
    expectedRewards: rewardWitness.map((reward) => reward.scaled.toString()),
    rewardRemainders: rewardWitness.map((reward) => reward.remainder.toString()),
    rawThresholds: allocation.rawThresholds.map((threshold) => threshold.toString()),
    thresholdRemainders: allocation.thresholdRemainders.map((remainder) => remainder.toString()),
    thresholds: allocation.thresholds.map((threshold) => threshold.toString()),
    expectedPayoutNumerator: allocation.expectedPayoutNumerator.toString(),
    payouts,
  };

  const circuitInput = {
    reports: inputs.reports,
    nonces: inputs.nonces,
    maciStateIndices: inputs.maciStateIndices,
    voterIds: inputs.voterIds,
    nonceCommitments: finalState.nonceCommitments,
    merklePathElements: vector.merklePaths.map((pathData) => pathData.pathElements),
    expectedScaled: vector.expectedRewards,
    rewardRemainders: vector.rewardRemainders,
    rawThresholds: vector.rawThresholds,
    thresholdRemainders: vector.thresholdRemainders,
    payouts,
    recipients: inputs.recipients,
    stakes: inputs.stakes,
    smoothing: inputs.smoothing,
    kappa: inputs.kappa,
    scale: inputs.scale,
    rhoTau: inputs.rhoTau,
    disputeId: inputs.disputeId,
    finalStateRoot: finalState.finalStateRoot,
    rewardBudget: inputs.rewardBudget,
    gammaScaled: inputs.gammaScaled,
    randomSeed: seed.randomSeed,
  };

  writeJson(path.join(__dirname, "../vectors/v2/reward_bernoulli_state.json"), vector);
  writeJson(path.join(__dirname, "../artifacts/v2/input.json"), circuitInput);
  console.log("Wrote vectors/v2/reward_bernoulli_state.json");
  console.log("Wrote artifacts/v2/input.json");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
