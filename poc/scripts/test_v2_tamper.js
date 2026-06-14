"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const { computeBernoulliLotteryPayouts } = require("../reference/reward_model");

const wasm = path.join(__dirname, "../artifacts/v2/reward_check_js/reward_check.wasm");
const validInputPath = path.join(__dirname, "../artifacts/v2/input.json");
const zkey = path.join(__dirname, "../artifacts/v2/reward_check_final.zkey");
const verificationKey = path.join(__dirname, "../artifacts/v2/verification_key.json");
const workDir = path.join(__dirname, "../artifacts/v2/tamper");

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function expectWitnessFailure(name, mutate) {
  const input = readJson(validInputPath);
  mutate(input);

  const inputFile = path.join(workDir, `${name}.json`);
  const witnessFile = path.join(workDir, `${name}.wtns`);
  writeJson(inputFile, input);

  const result = spawnSync(
    "npx",
    ["snarkjs", "wtns", "calculate", wasm, inputFile, witnessFile],
    { cwd: path.join(__dirname, ".."), encoding: "utf8" },
  );

  if (result.status === 0) {
    throw new Error(`${name} unexpectedly produced a valid witness`);
  }
  console.log(`${name}: witness rejected`);
}

function runSnarkjs(args, label) {
  const result = spawnSync("npx", ["snarkjs", ...args], {
    cwd: path.join(__dirname, ".."),
    encoding: "utf8",
  });
  if (result.status !== 0) {
    throw new Error(`${label} failed\n${result.stdout}\n${result.stderr}`);
  }
  return result;
}

function expectWitnessSuccess(name, input) {
  const inputFile = path.join(workDir, `${name}.json`);
  const witnessFile = path.join(workDir, `${name}.wtns`);
  writeJson(inputFile, input);
  runSnarkjs(["wtns", "calculate", wasm, inputFile, witnessFile], `${name} witness`);
  console.log(`${name}: witness accepted`);
  return witnessFile;
}

function expectProofSuccess(name, witnessFile) {
  if (!fs.existsSync(zkey) || !fs.existsSync(verificationKey)) {
    console.log(`${name}: proof skipped; zkey or verification key missing`);
    return;
  }
  const proofFile = path.join(workDir, `${name}.proof.json`);
  const publicFile = path.join(workDir, `${name}.public.json`);
  runSnarkjs(["groth16", "prove", zkey, witnessFile, proofFile, publicFile], `${name} prove`);
  runSnarkjs(["groth16", "verify", verificationKey, publicFile, proofFile], `${name} verify`);
  console.log(`${name}: proof verified`);
}

async function baselineInputFromValid() {
  const input = readJson(validInputPath);
  const allocation = await computeBernoulliLotteryPayouts({
    reports: input.reports,
    stakes: input.stakes,
    peerIndices: Array.from({ length: input.reports.length }, (_, i) => (i + 1) % input.reports.length),
    disputeId: input.disputeId,
    stateRoot: input.finalStateRoot,
    randomSeed: input.randomSeed,
    smoothing: input.smoothing,
    kappa: input.kappa,
    scale: input.scale,
    rhoTau: input.rhoTau,
    rewardBudget: input.rewardBudget,
    lotteryMode: "baseline",
    psiScaled: 0n,
  });

  return {
    ...input,
    lotteryMode: "0",
    psiScaled: "0",
    expectedScaled: allocation.rewardWitness.map((reward) => reward.scaled.toString()),
    rewardRemainders: allocation.rewardWitness.map((reward) => reward.remainder.toString()),
    rawThresholds: allocation.rawThresholds.map((threshold) => threshold.toString()),
    thresholdRemainders: allocation.thresholdRemainders.map((remainder) => remainder.toString()),
    adjustedThresholds: allocation.adjustedThresholds.map((threshold) => threshold.toString()),
    adjustedThresholdRemainders: allocation.adjustedThresholdRemainders.map((remainder) => remainder.toString()),
    payouts: allocation.payouts.map((payout) => payout.toString()),
  };
}

async function main() {
  if (!fs.existsSync(wasm) || !fs.existsSync(validInputPath)) {
    throw new Error("compile the v2 circuit and generate artifacts/v2/input.json first");
  }

  const baselineWitness = expectWitnessSuccess("baseline_mode", await baselineInputFromValid());
  expectProofSuccess("baseline_mode", baselineWitness);

  expectWitnessFailure("tampered_report", (input) => {
    input.reports[0] = input.reports[0] === 0 ? 1 : 0;
  });
  expectWitnessFailure("tampered_nonce", (input) => {
    input.nonces[0] = (BigInt(input.nonces[0]) + 1n).toString();
  });
  expectWitnessFailure("tampered_nonce_commitment", (input) => {
    input.nonceCommitments[0] = (BigInt(input.nonceCommitments[0]) + 1n).toString();
  });
  expectWitnessFailure("tampered_maci_state_index", (input) => {
    input.maciStateIndices[0] = (BigInt(input.maciStateIndices[0]) + 1n).toString();
  });
  expectWitnessFailure("tampered_stake", (input) => {
    input.stakes[0] = (BigInt(input.stakes[0]) + 1n).toString();
  });
  expectWitnessFailure("tampered_recipient", (input) => {
    input.recipients[0] = (BigInt(input.recipients[0]) + 1n).toString();
  });
  expectWitnessFailure("out_of_range_recipient", (input) => {
    input.recipients[0] = (1n << 160n).toString();
  });
  expectWitnessFailure("out_of_range_stake", (input) => {
    input.stakes[0] = (1n << 32n).toString();
  });
  expectWitnessFailure("out_of_range_reward_budget", (input) => {
    input.rewardBudget = (1n << 64n).toString();
  });
  expectWitnessFailure("out_of_range_psi", (input) => {
    input.psiScaled = (1n << 31n).toString();
  });
  expectWitnessFailure("zero_floor_adjusted_psi", (input) => {
    input.psiScaled = "0";
  });
  expectWitnessFailure("invalid_lottery_mode", (input) => {
    input.lotteryMode = "2";
  });
  expectWitnessFailure("out_of_range_rho_tau", (input) => {
    input.rhoTau = (1n << 64n).toString();
  });
  expectWitnessFailure("tampered_final_state_root", (input) => {
    input.finalStateRoot = (BigInt(input.finalStateRoot) + 1n).toString();
  });
  expectWitnessFailure("tampered_rho_tau", (input) => {
    input.rhoTau = (BigInt(input.rhoTau) - 1n).toString();
  });
  expectWitnessFailure("tampered_psi", (input) => {
    input.psiScaled = (BigInt(input.psiScaled) + 1n).toString();
  });
  expectWitnessFailure("tampered_random_seed", (input) => {
    input.randomSeed = (BigInt(input.randomSeed) + 1n).toString();
  });
  expectWitnessFailure("tampered_raw_threshold", (input) => {
    input.rawThresholds[0] = (BigInt(input.rawThresholds[0]) + 1n).toString();
  });
  expectWitnessFailure("tampered_adjusted_threshold", (input) => {
    input.adjustedThresholds[0] = (BigInt(input.adjustedThresholds[0]) + 1n).toString();
  });
  expectWitnessFailure("tampered_payout", (input) => {
    input.payouts[0] = (BigInt(input.payouts[0]) + 1n).toString();
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
