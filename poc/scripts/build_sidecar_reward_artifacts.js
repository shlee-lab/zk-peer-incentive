"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const ethers = require("ethers");
const {
  buildFinalState,
  computeBernoulliLotteryPayouts,
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

function gammaScaled(numerator, denominator, bits = 32n) {
  return (BigInt(numerator) * (1n << bits)) / BigInt(denominator);
}

function bytes32Label(label) {
  return `0x${crypto.createHash("sha256").update(label).digest("hex")}`;
}

function seedMaterial(sidecar, disputeId, finalStateRoot) {
  const seedPreimage = sidecar.seedPreimage
    ? BigInt(sidecar.seedPreimage)
    : fieldElement(`${sidecar.nonceLabel || "full-maci-reward-sidecar"} external lottery seed`);
  const seedSalt = sidecar.seedSalt || bytes32Label(`${sidecar.nonceLabel || "full-maci-reward-sidecar"} seed salt`);
  const seedCommitment = ethers.utils.solidityKeccak256(
    ["uint256", "bytes32"],
    [seedPreimage.toString(), seedSalt],
  );
  const randomSeed =
    BigInt(ethers.utils.solidityKeccak256(
      ["uint256", "bytes32", "uint256", "uint256"],
      [seedPreimage.toString(), seedSalt, disputeId.toString(), finalStateRoot.toString()],
    )) % FIELD_PRIME;
  return { seedPreimage, seedSalt, seedCommitment, randomSeed };
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
    rhoTau: BigInt(sidecar.rhoTau ?? 3_000_000),
    rewardBudget: BigInt(sidecar.rewardBudget ?? 24_000_000),
    gammaScaled: BigInt(sidecar.gammaScaled ?? gammaScaled(5n, 100n)),
  };
}

async function buildVector(sidecar, attempt) {
  const inputs = baseInputs(sidecar, attempt);
  const finalState = await buildFinalState(inputs);
  const seed = seedMaterial(sidecar, inputs.disputeId, finalState.finalStateRoot);
  const sidecarInputs = { ...inputs, nonceCommitments: finalState.nonceCommitments };
  const rewardInputs = {
    ...sidecarInputs,
    stateRoot: finalState.finalStateRoot,
    randomSeed: seed.randomSeed,
  };
  const allocation = await computeBernoulliLotteryPayouts(rewardInputs);
  const rewardWitness = allocation.rewardWitness;
  const payouts = allocation.payouts.map((payout) => payout.toString());

  const vector = {
    version: "full-maci-sidecar-bernoulli-lottery",
    description: "Coordinate-wise Bernoulli lottery reward vector derived from official MACI final poll reports with recipient and command-salt nonce binding.",
    inputs: rewardInputs,
    seedPreimage: seed.seedPreimage.toString(),
    seedSalt: seed.seedSalt,
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
    disputeId: publicSignals[28],
    finalStateRoot: publicSignals[29],
    proofGenerationMs,
    seedPreimage: vector.seedPreimage,
    seedSalt: vector.seedSalt,
    seedCommitment: vector.seedCommitment,
    randomSeed: vector.randomSeed,
  };
  writeJson(fixtureFile, fixture);

  const summary = {
    pollId: inputs.disputeId.toString(),
    finalRewardStateRoot: vector.finalStateRoot,
    nonceSource: sidecar.nonceSource || "maci-vote-command-salt",
    randomSeed: vector.randomSeed,
    seedCommitment: vector.seedCommitment,
    reports: inputs.reports,
    lotteryWins: vector.wins,
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
