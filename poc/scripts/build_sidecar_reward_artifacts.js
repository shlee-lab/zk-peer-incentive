"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const {
  buildFinalState,
  computeFixedBudgetPayouts,
  computeRewardDivisionWitness,
} = require("../reference/reward_model");

const FIELD_PRIME =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const N = 8;

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) {
      throw new Error(`unexpected positional argument: ${arg}`);
    }
    const key = arg.slice(2);
    const value = argv[i + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`missing value for --${key}`);
    }
    args[key] = value;
    i += 1;
  }
  return args;
}

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
}

function bigintReplacer(_, value) {
  return typeof value === "bigint" ? value.toString() : value;
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, bigintReplacer, 2)}\n`);
}

function toBigIntArray(values, label) {
  if (!Array.isArray(values) || values.length !== N) {
    throw new Error(`${label} must contain ${N} values`);
  }
  return values.map((value) => BigInt(value));
}

function toRecipientArray(values) {
  const recipients = toBigIntArray(values, "recipients");
  recipients.forEach((recipient, i) => {
    if (recipient <= 0n || recipient >= (1n << 160n)) {
      throw new Error(`recipients[${i}] must be a nonzero 160-bit address value`);
    }
  });
  return recipients;
}

function toReportArray(values) {
  if (!Array.isArray(values) || values.length !== N) {
    throw new Error(`reports must contain ${N} values`);
  }
  return values.map((value, i) => {
    const report = Number(value);
    if (report !== 0 && report !== 1) {
      throw new Error(`reports[${i}] must be 0 or 1`);
    }
    return report;
  });
}

function defaultNonces(label, attempt) {
  return Array.from({ length: N }, (_, i) => fieldElement(`${label} attempt ${attempt} nonce ${i}`));
}

function defaultStakes() {
  return [10n, 20n, 10n, 15n, 5n, 10n, 15n, 15n];
}

function baseInputs(sidecar, attempt) {
  return {
    reports: toReportArray(sidecar.reports),
    stakes: sidecar.stakes ? toBigIntArray(sidecar.stakes, "stakes") : defaultStakes(),
    peerIndices: Array.from({ length: N }, (_, i) => (i + 1) % N),
    maciStateIndices: toBigIntArray(sidecar.maciStateIndices, "maciStateIndices"),
    nonces: sidecar.nonces
      ? toBigIntArray(sidecar.nonces, "nonces")
      : defaultNonces(sidecar.nonceLabel || "full-maci-reward-sidecar", attempt),
    voterIds: toBigIntArray(sidecar.voterIds, "voterIds"),
    recipients: toRecipientArray(sidecar.recipients),
    disputeId: BigInt(sidecar.disputeId ?? sidecar.pollId),
    smoothing: BigInt(sidecar.smoothing ?? 1),
    kappa: BigInt(sidecar.kappa ?? 100),
    scale: BigInt(sidecar.scale ?? 1_000),
    rewardBudget: BigInt(sidecar.rewardBudget ?? 3_000_000),
  };
}

async function buildVector(sidecar, attempt) {
  const inputs = baseInputs(sidecar, attempt);
  const finalState = await buildFinalState(inputs);
  const sidecarInputs = { ...inputs, nonceCommitments: finalState.nonceCommitments };
  const rewardInputs = { ...sidecarInputs, stateRoot: finalState.finalStateRoot };
  const allocation = computeFixedBudgetPayouts(rewardInputs);
  const rewardWitness = computeRewardDivisionWitness(inputs);
  const payouts = allocation.payouts.map((payout) => payout.toString());
  const allocationRemainders = [...allocation.allocationRemainders, 0n].map((remainder) =>
    remainder.toString()
  );

  const vector = {
    version: "full-maci-sidecar-v2",
    description: "Fixed-budget reward vector derived from official MACI final poll reports with recipient and command-salt nonce binding.",
    inputs: rewardInputs,
    nonceCommitments: finalState.nonceCommitments.map((commitment) => commitment.toString()),
    leaves: finalState.leaves.map((leaf) => leaf.toString()),
    merklePaths: finalState.paths.map((pathData) => ({
      pathElements: pathData.pathElements.map((element) => element.toString()),
      pathIndices: pathData.pathIndices,
    })),
    finalStateRoot: finalState.finalStateRoot.toString(),
    expectedRewards: rewardWitness.map((reward) => reward.scaled.toString()),
    rewardRemainders: rewardWitness.map((reward) => reward.remainder.toString()),
    allocationBaseline: allocation.allocationBaseline.toString(),
    allocationScores: allocation.allocationScores.map((score) => score.toString()),
    totalAllocationScore: allocation.totalAllocationScore.toString(),
    allocationRemainders,
    payouts,
    nonceAttempt: attempt,
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
    allocationRemainders: vector.allocationRemainders,
    payouts,
    recipients: inputs.recipients,
    stakes: inputs.stakes,
    smoothing: inputs.smoothing,
    kappa: inputs.kappa,
    scale: inputs.scale,
    disputeId: inputs.disputeId,
    finalStateRoot: finalState.finalStateRoot,
    rewardBudget: inputs.rewardBudget,
  };

  return { inputs, vector, circuitInput };
}

function run(pocRoot, args) {
  const result = spawnSync(args[0], args.slice(1), {
    cwd: pocRoot,
    encoding: "utf8",
    stdio: "inherit",
  });
  if (result.status !== 0) {
    throw new Error(`${args.join(" ")} failed`);
  }
}

function requireFile(file, hint) {
  if (!fs.existsSync(file)) {
    throw new Error(`${hint}: ${file}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const pocRoot = path.resolve(__dirname, "..");
  const sidecarFile = path.resolve(args.sidecar || path.join(pocRoot, "artifacts/full_maci_reward/sidecar_input.json"));
  const outDir = path.resolve(args["out-dir"] || path.join(pocRoot, "artifacts/full_maci_reward/reward"));
  const fixtureFile = path.resolve(args.fixture || path.join(outDir, "reward_proof_fixture.json"));
  const wasm = path.join(pocRoot, "artifacts/v2/reward_check_js/reward_check.wasm");
  const zkey = path.join(pocRoot, "artifacts/v2/reward_check_final.zkey");
  const verificationKey = path.join(pocRoot, "artifacts/v2/verification_key.json");

  requireFile(sidecarFile, "missing MACI sidecar input");
  requireFile(wasm, "missing compiled reward circuit wasm; run the v2 circuit commands first");
  requireFile(zkey, "missing reward Groth16 zkey; run the v2 proving setup first");
  requireFile(verificationKey, "missing reward verification key; run the v2 proving setup first");

  const sidecar = readJson(sidecarFile);
  const { inputs, vector, circuitInput } = await buildVector(sidecar, 0);

  fs.mkdirSync(outDir, { recursive: true });
  const vectorFile = path.join(outDir, "reward_sidecar_vector.json");
  const inputFile = path.join(outDir, "input.json");
  const witnessFile = path.join(outDir, "witness.wtns");
  const proofFile = path.join(outDir, "proof.json");
  const publicFile = path.join(outDir, "public.json");
  const summaryFile = path.join(outDir, "summary.json");

  writeJson(vectorFile, vector);
  writeJson(inputFile, circuitInput);

  const startedAt = Date.now();
  run(pocRoot, ["npx", "snarkjs", "wtns", "calculate", wasm, inputFile, witnessFile]);
  run(pocRoot, ["npx", "snarkjs", "groth16", "prove", zkey, witnessFile, proofFile, publicFile]);
  run(pocRoot, ["npx", "snarkjs", "groth16", "verify", verificationKey, publicFile, proofFile]);
  const proofGenerationMs = Date.now() - startedAt;

  const proof = readJson(proofFile);
  const publicSignals = readJson(publicFile);
  const amounts = publicSignals.slice(0, N);
  const totalPayout = amounts.reduce((acc, value) => acc + BigInt(value), 0n);
  const recipients = sidecar.recipients || [];
  if (recipients.length !== N) {
    throw new Error(`recipients must contain ${N} addresses`);
  }

  const fixture = {
    proof,
    publicSignals,
    amounts,
    recipients,
    payoutCount: N,
    totalPayout: totalPayout.toString(),
    disputeId: publicSignals[27],
    finalStateRoot: publicSignals[28],
    proofGenerationMs,
  };
  writeJson(fixtureFile, fixture);

  const summary = {
    pollId: inputs.disputeId.toString(),
    finalRewardStateRoot: vector.finalStateRoot,
    nonceSource: sidecar.nonceSource || "maci-vote-command-salt",
    reports: inputs.reports,
    maciStateIndices: inputs.maciStateIndices.map((value) => value.toString()),
    tallyPayouts: amounts,
    totalPayout: totalPayout.toString(),
    paidRecipientIndices: amounts
      .map((amount, index) => ({ amount: BigInt(amount), index }))
      .filter(({ amount }) => amount > 0n)
      .map(({ index }) => index),
    nonceAttempt: vector.nonceAttempt,
    proofGenerationMs,
    files: {
      vector: vectorFile,
      input: inputFile,
      proof: proofFile,
      publicSignals: publicFile,
      fixture: fixtureFile,
    },
  };
  writeJson(summaryFile, summary);
  console.log(JSON.stringify(summary, bigintReplacer, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
