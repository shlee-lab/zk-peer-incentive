"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { performance } = require("perf_hooks");
const { spawnSync } = require("child_process");
const {
  buildFinalState,
  computeFixedBudgetLotteryPayouts,
} = require("../reference/reward_model");

const FIELD_PRIME =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const REPO_ROOT = path.resolve(__dirname, "../..");
const POC_DIR = path.resolve(__dirname, "..");
const DATA_DIR = path.join(REPO_ROOT, "experiments/reward-evaluation/data");
const ARTIFACT_DIR = path.join(POC_DIR, "artifacts/scaling");
const BASE_CIRCUIT = path.join(POC_DIR, "circuits/reward_check.circom");
const DEFAULT_PTAU = "/tmp/maci-official/zkeys/powersOfTau28_hez_final_19.ptau";
const MAX_VOTERS = Number(process.env.REWARD_SCALING_MAX_VOTERS || "64");
const ACTIVE_COUNTS = (process.env.REWARD_SCALING_ACTIVE_COUNTS || "8,16,32,64")
  .split(",")
  .map((value) => Number(value.trim()))
  .filter((value) => Number.isInteger(value) && value > 0);

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
}

function recipientValue(index) {
  return BigInt(`0x${crypto.createHash("sha256").update(`reward scaling recipient ${index}`).digest("hex").slice(0, 40)}`);
}

function bigintReplacer(_, value) {
  return typeof value === "bigint" ? value.toString() : value;
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, bigintReplacer, 2)}\n`);
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

function log2PowerOfTwo(n) {
  if ((n & (n - 1)) !== 0) {
    throw new Error(`N must be a power of two for the fixed Merkle tree: ${n}`);
  }
  return Math.log2(n);
}

function runCommand(label, args, options = {}) {
  const cwd = options.cwd || POC_DIR;
  console.log(`[scaling] ${label}`);
  const start = performance.now();
  const result = spawnSync(args[0], args.slice(1), {
    cwd,
    encoding: "utf8",
    maxBuffer: 200 * 1024 * 1024,
  });
  const elapsedMs = performance.now() - start;
  if (result.status !== 0) {
    if (result.stdout) process.stdout.write(result.stdout);
    if (result.stderr) process.stderr.write(result.stderr);
    throw new Error(`${label} failed with exit code ${result.status}`);
  }
  return {
    elapsedMs,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
  };
}

function makeCircuitVariant(n, depth, outDir) {
  const source = fs.readFileSync(BASE_CIRCUIT, "utf8");
  const variant = source
    .replaceAll('../node_modules/circomlib/circuits/', '../../../node_modules/circomlib/circuits/')
    .replace(
      /component main \{ public \[payouts, recipients, stakes, smoothing, kappa, scale, rhoTau, disputeId, finalStateRoot, rewardBudget\] \} = RewardCheck\(8, 3, 128, 32\);/,
      `component main { public [payouts, recipients, stakes, smoothing, kappa, scale, rhoTau, disputeId, finalStateRoot, rewardBudget] } = RewardCheck(${n}, ${depth}, 128, 32);`
    );
  const file = path.join(outDir, `reward_check_${n}.circom`);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(file, variant);
  return file;
}

function activePositions(maxVoters, activeVoters) {
  if (activeVoters > maxVoters) {
    throw new Error(`active voters ${activeVoters} exceed max voters ${maxVoters}`);
  }
  if (activeVoters === maxVoters) {
    return Array.from({ length: maxVoters }, (_, i) => i);
  }
  const positions = Array.from({ length: activeVoters - 1 }, (_, i) => i);
  positions.push(maxVoters - 1);
  return positions;
}

function makeInputs(maxVoters, activeVoters) {
  const basePattern = [1, 0, 1, 1, 0, 0, 1, 0];
  const active = new Set(activePositions(maxVoters, activeVoters));
  const reports = Array.from({ length: maxVoters }, () => 0);
  const stakes = Array.from({ length: maxVoters }, () => 0n);
  const recipients = Array.from({ length: maxVoters }, () => 0n);
  const orderedActive = [...active].sort((a, b) => a - b);
  orderedActive.forEach((position, activeIndex) => {
    reports[position] = basePattern[activeIndex % basePattern.length];
    stakes[position] = 10n;
    recipients[position] = recipientValue(activeIndex);
  });
  if (activeVoters < maxVoters && activeVoters > 1) {
    reports[activeVoters - 1] = reports[activeVoters - 2];
  }
  return {
    reports,
    stakes,
    peerIndices: Array.from({ length: maxVoters }, (_, i) => (i + 1) % maxVoters),
    maciStateIndices: Array.from({ length: maxVoters }, (_, i) => BigInt(i + 1)),
    nonces: Array.from({ length: maxVoters }, (_, i) =>
      fieldElement(`reward utilization nonce ${maxVoters} ${activeVoters} ${i}`)
    ),
    voterIds: Array.from({ length: maxVoters }, (_, i) =>
      fieldElement(`reward utilization voter ${maxVoters} ${activeVoters} ${i}`)
    ),
    recipients,
    disputeId: 78n,
    smoothing: 1n,
    kappa: 100n,
    scale: 1_000n,
    rhoTau: 3_000_000n,
    rewardBudget: 3_000_000n,
  };
}

async function makeCircuitInput(inputs) {
  const finalState = await buildFinalState(inputs);
  const rewardInputs = {
    ...inputs,
    nonceCommitments: finalState.nonceCommitments,
    stateRoot: finalState.finalStateRoot,
  };
  const allocation = await computeFixedBudgetLotteryPayouts(rewardInputs);
  const allocationRemainders = [...allocation.allocationRemainders, 0n];

  if (allocation.payouts.reduce((acc, payout) => acc + payout, 0n) !== inputs.rewardBudget) {
    throw new Error("scaling vector does not distribute the fixed reward budget");
  }

  return {
    input: {
      reports: inputs.reports,
      nonces: inputs.nonces,
      maciStateIndices: inputs.maciStateIndices,
      voterIds: inputs.voterIds,
      nonceCommitments: finalState.nonceCommitments,
      merklePathElements: finalState.paths.map((pathData) => pathData.pathElements),
      expectedScaled: allocation.rewardWitness.map((reward) => reward.scaled),
      rewardRemainders: allocation.rewardWitness.map((reward) => reward.remainder),
      allocationRemainders,
      payouts: allocation.payouts,
      recipients: inputs.recipients,
      stakes: inputs.stakes,
      smoothing: inputs.smoothing,
      kappa: inputs.kappa,
      scale: inputs.scale,
      rhoTau: inputs.rhoTau,
      disputeId: inputs.disputeId,
      finalStateRoot: finalState.finalStateRoot,
      rewardBudget: inputs.rewardBudget,
    },
    allocation,
    finalState,
  };
}

function parseR1csInfo(output) {
  const constraints = output.match(/# of Constraints:\s+(\d+)/);
  const wires = output.match(/# of Wires:\s+(\d+)/);
  const labels = output.match(/# of Labels:\s+(\d+)/);
  return {
    constraints: constraints ? Number(constraints[1]) : "",
    wires: wires ? Number(wires[1]) : "",
    labels: labels ? Number(labels[1]) : "",
  };
}

async function compileCapacity(maxVoters, ptau) {
  const depth = log2PowerOfTwo(maxVoters);
  const outDir = path.join(ARTIFACT_DIR, `max${maxVoters}`);
  fs.rmSync(outDir, { recursive: true, force: true });
  fs.mkdirSync(outDir, { recursive: true });

  const circuitFile = makeCircuitVariant(maxVoters, depth, outDir);

  const compile = runCommand(`compile maxN=${maxVoters}`, [
    "circom",
    circuitFile,
    "--r1cs",
    "--wasm",
    "--sym",
    "-o",
    outDir,
  ]);

  const r1cs = path.join(outDir, `reward_check_${maxVoters}.r1cs`);
  const wasmDir = path.join(outDir, `reward_check_${maxVoters}_js`);
  const zkey = path.join(outDir, `reward_check_${maxVoters}.zkey`);
  const vk = path.join(outDir, "verification_key.json");

  const info = runCommand(`r1cs info maxN=${maxVoters}`, ["npx", "snarkjs", "r1cs", "info", r1cs]);
  const setup = runCommand(`groth16 setup maxN=${maxVoters}`, [
    "npx",
    "snarkjs",
    "groth16",
    "setup",
    r1cs,
    ptau,
    zkey,
  ]);
  const exportVk = runCommand(`export vk maxN=${maxVoters}`, [
    "npx",
    "snarkjs",
    "zkey",
    "export",
    "verificationkey",
    zkey,
    vk,
  ]);
  const r1csInfo = parseR1csInfo(info.stdout + info.stderr);

  return {
    maxVoters,
    depth,
    outDir,
    r1cs,
    wasmDir,
    zkey,
    vk,
    compileMs: Math.round(compile.elapsedMs),
    setupMs: Math.round(setup.elapsedMs),
    exportVkMs: Math.round(exportVk.elapsedMs),
    r1csInfo,
  };
}

async function runForActiveCount(capacity, activeVoters) {
  const outDir = path.join(capacity.outDir, `active${activeVoters}`);
  fs.mkdirSync(outDir, { recursive: true });
  const { input, allocation } = await makeCircuitInput(makeInputs(capacity.maxVoters, activeVoters));
  const inputFile = path.join(outDir, "input.json");
  const witness = path.join(outDir, "witness.wtns");
  const proof = path.join(outDir, "proof.json");
  const pub = path.join(outDir, "public.json");
  writeJson(inputFile, input);

  const witnessGen = runCommand(`witness maxN=${capacity.maxVoters} active=${activeVoters}`, [
    "node",
    path.join(capacity.wasmDir, "generate_witness.js"),
    path.join(capacity.wasmDir, `reward_check_${capacity.maxVoters}.wasm`),
    inputFile,
    witness,
  ]);
  const prove = runCommand(`prove maxN=${capacity.maxVoters} active=${activeVoters}`, [
    "npx",
    "snarkjs",
    "groth16",
    "prove",
    capacity.zkey,
    witness,
    proof,
    pub,
  ]);
  const verify = runCommand(`verify maxN=${capacity.maxVoters} active=${activeVoters}`, [
    "npx",
    "snarkjs",
    "groth16",
    "verify",
    capacity.vk,
    pub,
    proof,
  ]);
  const totalPayout = allocation.payouts.reduce((acc, payout) => acc + payout, 0n);
  const paidRecipientCount = allocation.payouts.filter((payout) => payout > 0n).length;

  return {
    maxVoters: capacity.maxVoters,
    activeVoters,
    utilization: (activeVoters / capacity.maxVoters).toFixed(6),
    merkleDepth: capacity.depth,
    publicInputs: 3 * capacity.maxVoters + 7,
    privateInputs: capacity.maxVoters * (8 + capacity.depth),
    constraints: capacity.r1csInfo.constraints,
    wires: capacity.r1csInfo.wires,
    labels: capacity.r1csInfo.labels,
    compileMs: capacity.compileMs,
    witnessMs: Math.round(witnessGen.elapsedMs),
    setupMs: capacity.setupMs,
    exportVkMs: capacity.exportVkMs,
    proveMs: Math.round(prove.elapsedMs),
    verifyMs: Math.round(verify.elapsedMs),
    proveMsPerActiveVoter: Math.round(prove.elapsedMs / activeVoters),
    totalPayout: totalPayout.toString(),
    paidRecipientCount,
    winnerCount: allocation.wins.filter((win) => win === 1n).length,
    artifactDir: path.relative(REPO_ROOT, outDir),
    verifyOutput: (verify.stdout + verify.stderr).includes("OK") ? "OK" : "unknown",
  };
}

async function main() {
  const ptau = process.env.REWARD_SCALING_PTAU || DEFAULT_PTAU;
  if (!fs.existsSync(ptau)) {
    throw new Error(`missing ptau file: ${ptau}`);
  }
  if (!Number.isInteger(MAX_VOTERS) || MAX_VOTERS <= 0) {
    throw new Error("REWARD_SCALING_MAX_VOTERS must be a positive integer");
  }
  log2PowerOfTwo(MAX_VOTERS);
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const capacity = await compileCapacity(MAX_VOTERS, ptau);
  const rows = [];
  for (const activeVoters of ACTIVE_COUNTS) {
    rows.push(await runForActiveCount(capacity, activeVoters));
    writeCsv(path.join(DATA_DIR, "reward_scaling.csv"), rows);
    writeCsv(path.join(DATA_DIR, "reward_utilization.csv"), rows);
  }
  writeJson(path.join(DATA_DIR, "reward_scaling_manifest.json"), {
    generatedAt: new Date().toISOString(),
    maxVoters: MAX_VOTERS,
    activeVoterCounts: ACTIVE_COUNTS,
    ptau,
    relation: "fixed-capacity reward circuit utilization with Poseidon-fold lottery seed",
    note: "Artifacts are generated under poc/artifacts/scaling and are intentionally gitignored.",
  });
  console.log(`Wrote ${path.join(DATA_DIR, "reward_scaling.csv")}`);
  console.log(`Wrote ${path.join(DATA_DIR, "reward_utilization.csv")}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
