"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const wasm = path.join(__dirname, "../artifacts/v2/reward_check_js/reward_check.wasm");
const validInputPath = path.join(__dirname, "../artifacts/v2/input.json");
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

function main() {
  if (!fs.existsSync(wasm) || !fs.existsSync(validInputPath)) {
    throw new Error("compile the v2 circuit and generate artifacts/v2/input.json first");
  }

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
  expectWitnessFailure("tampered_final_state_root", (input) => {
    input.finalStateRoot = (BigInt(input.finalStateRoot) + 1n).toString();
  });
  expectWitnessFailure("tampered_payout", (input) => {
    input.payouts[0] = (BigInt(input.payouts[0]) + 1n).toString();
  });
}

main();
