"use strict";

const crypto = require("crypto");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { performance } = require("perf_hooks");
const { spawn, spawnSync } = require("child_process");
const ethers = require("ethers");
const {
  buildFinalState,
  computeBernoulliLotteryPayouts,
} = require("../reference/reward_model");

const FIELD_PRIME =
  21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const REPO_ROOT = path.resolve(__dirname, "../..");
const POC_DIR = path.resolve(__dirname, "..");
const RESULTS_DIR = path.join(REPO_ROOT, "results");
const RESULTS_FIG_DIR = path.join(RESULTS_DIR, "figures");
const ARTIFACT_DIR = path.join(POC_DIR, "artifacts/reward_layer_scaling");
const GENERATED_CONTRACT_DIR = path.join(POC_DIR, "contracts/scaling_generated");
const BASE_CIRCUIT = path.join(POC_DIR, "circuits/reward_check.circom");
const DEFAULT_PTAU = "/tmp/maci-official/zkeys/powersOfTau28_hez_final_19.ptau";
const RPC_URL = process.env.REWARD_LAYER_SCALING_RPC_URL || "http://127.0.0.1:8567";
const N_VALUES = (process.env.REWARD_LAYER_SCALING_N || "8,16,32,64")
  .split(",")
  .map((value) => Number(value.trim()))
  .filter((value) => Number.isInteger(value) && value > 0);
const REPETITIONS = Number(process.env.REWARD_LAYER_SCALING_REPETITIONS || "1");
const LOTTERY_BITS = 32n;
const LOTTERY_SCALE = 1n << LOTTERY_BITS;
const PSI_NUMERATOR = 10n;
const PSI_DENOMINATOR = 100n;
const PSI_SCALED = (PSI_NUMERATOR * LOTTERY_SCALE) / PSI_DENOMINATOR;
const RHO_TAU = 3_000_000n;
const RHO_TAU_EFF = ((LOTTERY_SCALE - 2n * PSI_SCALED) * RHO_TAU) / LOTTERY_SCALE;

function fieldElement(label) {
  return BigInt(`0x${crypto.createHash("sha256").update(label).digest("hex")}`) % FIELD_PRIME;
}

function bytes32Label(label) {
  return `0x${crypto.createHash("sha256").update(label).digest("hex")}`;
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

function runCommand(label, args, options = {}) {
  console.log(`[reward-layer-scaling] ${label}`);
  const start = performance.now();
  const result = spawnSync(args[0], args.slice(1), {
    cwd: options.cwd || POC_DIR,
    encoding: "utf8",
    maxBuffer: 500 * 1024 * 1024,
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

function log2PowerOfTwo(n) {
  if ((n & (n - 1)) !== 0) {
    throw new Error(`N must be a power of two: ${n}`);
  }
  return Math.log2(n);
}

function makeCircuitVariant(n, depth, outDir) {
  const source = fs.readFileSync(BASE_CIRCUIT, "utf8");
  const variant = source
    .replaceAll('../node_modules/circomlib/circuits/', '../../../node_modules/circomlib/circuits/')
    .replace(
      /component main \{ public \[payouts, recipients, stakes, smoothing, kappa, scale, rhoTau, disputeId, finalStateRoot, rewardBudget, lotteryMode, psiScaled, randomSeed\] \} = RewardCheck\(8, 3, 128, 32\);/,
      `component main { public [payouts, recipients, stakes, smoothing, kappa, scale, rhoTau, disputeId, finalStateRoot, rewardBudget, lotteryMode, psiScaled, randomSeed] } = RewardCheck(${n}, ${depth}, 128, 32);`
    );
  const file = path.join(outDir, `reward_check_${n}.circom`);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(file, variant);
  return file;
}

function parseR1csInfo(output) {
  const constraints = output.match(/# of Constraints:\s+(\d+)/);
  const wires = output.match(/# of Wires:\s+(\d+)/);
  const labels = output.match(/# of Labels:\s+(\d+)/);
  const publicInputs = output.match(/# of Public Inputs:\s+(\d+)/);
  const privateInputs = output.match(/# of Private Inputs:\s+(\d+)/);
  return {
    constraints: constraints ? Number(constraints[1]) : 0,
    wires: wires ? Number(wires[1]) : 0,
    labels: labels ? Number(labels[1]) : 0,
    publicInputs: publicInputs ? Number(publicInputs[1]) : 0,
    privateInputs: privateInputs ? Number(privateInputs[1]) : 0,
  };
}

function seedMaterial(label, disputeId, finalStateRoot) {
  const seedPreimage = fieldElement(`${label} seed preimage`);
  const seedSalt = bytes32Label(`${label} seed salt`);
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

function addressToField(address) {
  return BigInt(address);
}

function makeBaseInputs(n, recipients, attempt) {
  const basePattern = [1, 0, 1, 1, 0, 0, 1, 0];
  return {
    reports: Array.from({ length: n }, (_, i) => basePattern[i % basePattern.length]),
    stakes: Array.from({ length: n }, () => 10n),
    peerIndices: Array.from({ length: n }, (_, i) => (i + 1) % n),
    maciStateIndices: Array.from({ length: n }, (_, i) => BigInt(i + 1)),
    nonces: Array.from({ length: n }, (_, i) => fieldElement(`reward layer scaling nonce ${n} ${attempt} ${i}`)),
    voterIds: Array.from({ length: n }, (_, i) => fieldElement(`reward layer scaling voter ${n} ${attempt} ${i}`)),
    recipients: recipients.map(addressToField),
    disputeId: BigInt(78 + n),
    smoothing: 1n,
    kappa: 100n,
    scale: 1_000n,
    rhoTau: RHO_TAU,
    rewardBudget: BigInt(n) * RHO_TAU,
    lotteryMode: 1n,
    psiScaled: PSI_SCALED,
  };
}

async function makeCircuitInput(n, recipients) {
  for (let attempt = 0; attempt < 32; attempt += 1) {
    const inputs = makeBaseInputs(n, recipients, attempt);
    const finalState = await buildFinalState(inputs);
    const seed = seedMaterial(`reward layer scaling ${n} ${attempt}`, inputs.disputeId, finalState.finalStateRoot);
    const rewardInputs = {
      ...inputs,
      nonceCommitments: finalState.nonceCommitments,
      stateRoot: finalState.finalStateRoot,
      randomSeed: seed.randomSeed,
    };
    const allocation = await computeBernoulliLotteryPayouts(rewardInputs);
    const totalPayout = allocation.payouts.reduce((acc, payout) => acc + payout, 0n);
    if (totalPayout === 0n) continue;
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
        rawThresholds: allocation.rawThresholds,
        thresholdRemainders: allocation.thresholdRemainders,
        adjustedThresholds: allocation.adjustedThresholds,
        adjustedThresholdRemainders: allocation.adjustedThresholdRemainders,
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
        lotteryMode: inputs.lotteryMode,
        psiScaled: inputs.psiScaled,
        randomSeed: seed.randomSeed,
      },
      allocation,
      finalState,
      seed,
      attempt,
      totalPayout,
    };
  }
  throw new Error(`could not find a nonzero payout vector for N=${n}`);
}

function encodeProof(proof) {
  const a = [proof.pi_a[0], proof.pi_a[1]];
  const b = [
    [proof.pi_b[0][1], proof.pi_b[0][0]],
    [proof.pi_b[1][1], proof.pi_b[1][0]],
  ];
  const c = [proof.pi_c[0], proof.pi_c[1]];
  return ethers.utils.defaultAbiCoder.encode(
    ["uint256[2]", "uint256[2][2]", "uint256[2]"],
    [a, b, c],
  );
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeGeneratedAdapter(n, publicSignalCount) {
  fs.mkdirSync(GENERATED_CONTRACT_DIR, { recursive: true });
  const adapter = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../IRewardVerifier.sol";
import "./RewardGroth16Verifier${n}.sol";

contract RewardVerifierAdapter${n} is IRewardVerifier {
    uint256 public constant PUBLIC_SIGNAL_COUNT = ${publicSignalCount};

    Groth16Verifier public immutable verifier;

    constructor(Groth16Verifier verifier_) {
        verifier = verifier_;
    }

    function verifyProof(bytes calldata proof, uint256[] calldata publicSignals) external view returns (bool) {
        if (publicSignals.length != PUBLIC_SIGNAL_COUNT) {
            return false;
        }

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            abi.decode(proof, (uint256[2], uint256[2][2], uint256[2]));

        uint256[${publicSignalCount}] memory signals;
        for (uint256 i = 0; i < PUBLIC_SIGNAL_COUNT; i++) {
            signals[i] = publicSignals[i];
        }

        return verifier.verifyProof(a, b, c, signals);
    }
}
`;
  fs.writeFileSync(path.join(GENERATED_CONTRACT_DIR, `RewardVerifierAdapter${n}.sol`), adapter);
}

function artifact(contractFile, contractName) {
  const file = path.join(POC_DIR, `out/${contractFile}/${contractName}.json`);
  if (!fs.existsSync(file)) {
    throw new Error(`missing artifact ${file}; run forge build first`);
  }
  const data = readJson(file);
  return {
    abi: data.abi,
    bytecode: data.bytecode.object || data.bytecode,
  };
}

async function deploy(label, signer, contractFile, contractName, args = []) {
  const art = artifact(contractFile, contractName);
  const factory = new ethers.ContractFactory(art.abi, art.bytecode, signer);
  const contract = await factory.deploy(...args);
  const receipt = await contract.deployTransaction.wait();
  console.log(`[reward-layer-scaling] deploy ${label}: gas=${receipt.gasUsed.toString()}`);
  return { contract, gas: receipt.gasUsed.toNumber(), tx: receipt.transactionHash };
}

async function waitTx(label, tx) {
  const receipt = await tx.wait();
  console.log(`[reward-layer-scaling] ${label}: gas=${receipt.gasUsed.toString()}`);
  return { gas: receipt.gasUsed.toNumber(), tx: receipt.transactionHash };
}

async function canConnect(provider) {
  try {
    await provider.getBlockNumber();
    return true;
  } catch {
    return false;
  }
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function startAnvilIfNeeded(provider) {
  if (await canConnect(provider)) {
    console.log(`[reward-layer-scaling] using existing RPC ${RPC_URL}`);
    return null;
  }
  if (process.env.REWARD_LAYER_SCALING_RPC_URL) {
    throw new Error(`REWARD_LAYER_SCALING_RPC_URL is set but unreachable: ${RPC_URL}`);
  }
  const url = new URL(RPC_URL);
  const child = spawn(
    "anvil",
    [
      "--host",
      url.hostname,
      "--port",
      url.port || "8545",
      "--accounts",
      "200",
      "--balance",
      "10000",
      "--gas-limit",
      "30000000",
      "--code-size-limit",
      "1000000",
      "--silent",
    ],
    { stdio: ["ignore", "pipe", "pipe"] },
  );
  for (let i = 0; i < 80; i += 1) {
    if (await canConnect(provider)) return child;
    await sleep(250);
  }
  child.kill();
  throw new Error("Anvil did not become ready");
}

function publicSignalCount(n) {
  return 3 * n + 10;
}

function privateInputCount(n) {
  return n * (11 + log2PowerOfTwo(n));
}

function signalIndex(n) {
  return {
    rhoTau: 3 * n + 3,
    disputeId: 3 * n + 4,
    finalStateRoot: 3 * n + 5,
    rewardBudget: 3 * n + 6,
    lotteryMode: 3 * n + 7,
    psiScaled: 3 * n + 8,
    randomSeed: 3 * n + 9,
  };
}

async function compileAndProve(n, recipients, ptau) {
  const depth = log2PowerOfTwo(n);
  const outDir = path.join(ARTIFACT_DIR, `n${n}`);
  fs.rmSync(outDir, { recursive: true, force: true });
  fs.mkdirSync(outDir, { recursive: true });

  const circuitFile = makeCircuitVariant(n, depth, outDir);
  const compile = runCommand(`compile N=${n}`, ["circom", circuitFile, "--r1cs", "--wasm", "--sym", "-o", outDir]);

  const r1cs = path.join(outDir, `reward_check_${n}.r1cs`);
  const wasmDir = path.join(outDir, `reward_check_${n}_js`);
  const zkey = path.join(outDir, `reward_check_${n}.zkey`);
  const vk = path.join(outDir, "verification_key.json");
  const info = runCommand(`r1cs info N=${n}`, ["npx", "snarkjs", "r1cs", "info", r1cs]);
  const r1csInfo = parseR1csInfo(info.stdout + info.stderr);
  const setup = runCommand(`groth16 setup N=${n}`, ["npx", "snarkjs", "groth16", "setup", r1cs, ptau, zkey]);
  const exportVk = runCommand(`export verification key N=${n}`, [
    "npx",
    "snarkjs",
    "zkey",
    "export",
    "verificationkey",
    zkey,
    vk,
  ]);

  const vector = await makeCircuitInput(n, recipients);
  const inputFile = path.join(outDir, "input.json");
  const witness = path.join(outDir, "witness.wtns");
  const proofFile = path.join(outDir, "proof.json");
  const publicFile = path.join(outDir, "public.json");
  writeJson(inputFile, vector.input);

  const witnessGen = runCommand(`witness N=${n}`, [
    "node",
    path.join(wasmDir, "generate_witness.js"),
    path.join(wasmDir, `reward_check_${n}.wasm`),
    inputFile,
    witness,
  ]);
  const prove = runCommand(`prove N=${n}`, ["npx", "snarkjs", "groth16", "prove", zkey, witness, proofFile, publicFile]);
  const verify = runCommand(`verify N=${n}`, ["npx", "snarkjs", "groth16", "verify", vk, publicFile, proofFile]);
  const verifierSource = path.join(GENERATED_CONTRACT_DIR, `RewardGroth16Verifier${n}.sol`);
  fs.rmSync(GENERATED_CONTRACT_DIR, { recursive: true, force: true });
  fs.mkdirSync(GENERATED_CONTRACT_DIR, { recursive: true });
  const exportSolidity = runCommand(`export solidity verifier N=${n}`, [
    "npx",
    "snarkjs",
    "zkey",
    "export",
    "solidityverifier",
    zkey,
    verifierSource,
  ]);
  writeGeneratedAdapter(n, publicSignalCount(n));

  return {
    n,
    depth,
    outDir,
    r1csInfo,
    compileMs: Math.round(compile.elapsedMs),
    setupMs: Math.round(setup.elapsedMs),
    exportVkMs: Math.round(exportVk.elapsedMs),
    witnessMs: Math.round(witnessGen.elapsedMs),
    proveMs: Math.round(prove.elapsedMs),
    verifyMs: Math.round(verify.elapsedMs),
    exportSolidityMs: Math.round(exportSolidity.elapsedMs),
    proof: readJson(proofFile),
    publicSignals: readJson(publicFile),
    vector,
    proofFile,
    publicFile,
    verifyOutput: (verify.stdout + verify.stderr).includes("OK") ? "OK" : "unknown",
  };
}

async function measureGas(n, benchmark, signer) {
  runCommand(`forge build for N=${n}`, ["forge", "build", "--force"]);

  const { contract: verifier, gas: verifierDeployGas } = await deploy(
    `Groth16Verifier N=${n}`,
    signer,
    `RewardGroth16Verifier${n}.sol`,
    "Groth16Verifier",
  );
  const { contract: adapter, gas: adapterDeployGas } = await deploy(
    `RewardVerifierAdapter${n}`,
    signer,
    `RewardVerifierAdapter${n}.sol`,
    `RewardVerifierAdapter${n}`,
    [verifier.address],
  );
  const { contract: registry, gas: registryDeployGas } = await deploy(
    `FinalStateRegistry N=${n}`,
    signer,
    "FinalStateRegistry.sol",
    "FinalStateRegistry",
  );
  const { contract: pool, gas: poolDeployGas } = await deploy(
    `ScalingRewardPool N=${n}`,
    signer,
    "ScalingRewardPool.sol",
    "ScalingRewardPool",
    [adapter.address, registry.address, n],
  );
  const { contract: probe, gas: probeDeployGas } = await deploy(
    `ScalingVerifierGasProbe N=${n}`,
    signer,
    "ScalingVerifierGasProbe.sol",
    "ScalingVerifierGasProbe",
  );

  const idx = signalIndex(n);
  const proof = encodeProof(benchmark.proof);
  const publicSignals = benchmark.publicSignals;
  const amounts = publicSignals.slice(0, n);
  const recipients = publicSignals.slice(n, 2 * n).map((value) =>
    ethers.utils.getAddress(ethers.utils.hexZeroPad(ethers.BigNumber.from(value).toHexString(), 20))
  );
  const disputeId = ethers.BigNumber.from(publicSignals[idx.disputeId]);
  const finalStateRoot = ethers.BigNumber.from(publicSignals[idx.finalStateRoot]);
  const rhoTau = BigInt(publicSignals[idx.rhoTau]);
  const maxExposure = BigInt(n) * rhoTau;

  const commit = await waitTx(
    `commit seed N=${n}`,
    await registry.commitRandomSeed(disputeId, benchmark.vector.seed.seedCommitment),
  );
  const register = await waitTx(
    `register root N=${n}`,
    await registry.registerFinalState(disputeId, finalStateRoot, 1),
  );
  const reveal = await waitTx(
    `reveal seed N=${n}`,
    await registry.revealRandomSeed(disputeId, benchmark.vector.seed.seedPreimage, benchmark.vector.seed.seedSalt),
  );
  const fund = await waitTx(`fund N=${n}`, await pool.fundDispute(disputeId, { value: maxExposure.toString() }));
  const verifierProbe = await waitTx(`verifier probe N=${n}`, await probe.verify(adapter.address, proof, publicSignals));
  const finalize = await waitTx(
    `finalize N=${n}`,
    await pool.finalizeRewards(disputeId, recipients, amounts, proof, publicSignals),
  );

  const claimIndex = amounts.findIndex((amount) => BigInt(amount) > 0n);
  if (claimIndex < 0) throw new Error(`N=${n} has no positive payout to claim`);
  const claimSigner = signer.provider.getSigner(recipients[claimIndex]);
  const claim = await waitTx(`claim N=${n}`, await pool.connect(claimSigner).claim(disputeId));

  const finalizeData = pool.interface.encodeFunctionData("finalizeRewards", [
    disputeId,
    recipients,
    amounts,
    proof,
    publicSignals,
  ]);
  const transcriptSizeBytes = (finalizeData.length - 2) / 2;
  const paidRecipientCount = amounts.filter((amount) => BigInt(amount) > 0n).length;

  return {
    verifierDeployGas,
    adapterDeployGas,
    registryDeployGas,
    poolDeployGas,
    probeDeployGas,
    commitRandomSeedGas: commit.gas,
    rewardRootRegistrationGas: register.gas,
    revealRandomSeedGas: reveal.gas,
    rewardPoolFundingGas: fund.gas,
    solidityVerifierGas: verifierProbe.gas,
    rewardFinalizationGas: finalize.gas,
    oneRecipientClaimGas: claim.gas,
    totalRewardLayerGasExcludingClaims: commit.gas + register.gas + reveal.gas + fund.gas + finalize.gas,
    totalClaimGasIfAllNRecipientsClaim: claim.gas * n,
    totalClaimGasForPaidRecipients: claim.gas * paidRecipientCount,
    paidRecipientCount,
    rewardTranscriptSizeBytes: transcriptSizeBytes,
    payoutVectorLength: n,
    totalPayout: amounts.reduce((acc, amount) => acc + BigInt(amount), 0n).toString(),
  };
}

function machineSpecs() {
  const cpus = os.cpus();
  return {
    platform: `${os.type()} ${os.release()} ${os.arch()}`,
    node: process.version,
    cpuModel: cpus[0] ? cpus[0].model : "unknown",
    logicalCores: cpus.length,
    totalMemoryBytes: os.totalmem(),
  };
}

async function main() {
  if (!Number.isInteger(REPETITIONS) || REPETITIONS !== 1) {
    throw new Error("Only single-run measurements are currently supported; set REWARD_LAYER_SCALING_REPETITIONS=1");
  }
  const ptau = process.env.REWARD_LAYER_SCALING_PTAU || DEFAULT_PTAU;
  if (!fs.existsSync(ptau)) {
    throw new Error(`missing ptau file: ${ptau}`);
  }
  N_VALUES.forEach(log2PowerOfTwo);
  fs.mkdirSync(RESULTS_DIR, { recursive: true });
  fs.mkdirSync(RESULTS_FIG_DIR, { recursive: true });

  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const anvil = await startAnvilIfNeeded(provider);
  try {
    const accounts = await provider.listAccounts();
    const maxN = Math.max(...N_VALUES);
    if (accounts.length < maxN + 1) {
      throw new Error(`need at least ${maxN + 1} unlocked accounts; got ${accounts.length}`);
    }
    const signer = provider.getSigner(accounts[0]);
    const rows = [];
    const artifacts = [];
    for (const n of N_VALUES) {
      const recipients = accounts.slice(1, n + 1);
      const benchmark = await compileAndProve(n, recipients, ptau);
      const gas = await measureGas(n, benchmark, signer);
      const row = {
        N: n,
        rewardCircuitConstraints: benchmark.r1csInfo.constraints,
        publicInputsCount: benchmark.r1csInfo.publicInputs || publicSignalCount(n),
        privateInputsCount: benchmark.r1csInfo.privateInputs || privateInputCount(n),
        witnessGenerationTimeMs: benchmark.witnessMs,
        proofGenerationTimeMs: benchmark.proveMs,
        proofVerificationTimeMs: benchmark.verifyMs,
        solidityVerifierGas: gas.solidityVerifierGas,
        rewardRootRegistrationGas: gas.rewardRootRegistrationGas,
        rewardFinalizationGas: gas.rewardFinalizationGas,
        totalRewardLayerGasExcludingIndividualClaims: gas.totalRewardLayerGasExcludingClaims,
        oneRecipientClaimGas: gas.oneRecipientClaimGas,
        totalClaimGasIfAllNRecipientsClaim: gas.totalClaimGasIfAllNRecipientsClaim,
        rewardTranscriptSizeBytes: gas.rewardTranscriptSizeBytes,
        payoutVectorLength: gas.payoutVectorLength,
        peerGraphDegree: 1,
        sampledPeersPerReporter: 1,
        payoutMode: "floor_adjusted_lottery",
        psi: "0.10",
        psiScaled: PSI_SCALED.toString(),
        rewardCapRhoTau: RHO_TAU.toString(),
        effectiveRewardCapacityRhoTauEff: RHO_TAU_EFF.toString(),
        paidRecipientCount: gas.paidRecipientCount,
        totalPayout: gas.totalPayout,
        merkleDepth: benchmark.depth,
        setupTimeMs: benchmark.setupMs,
        compileTimeMs: benchmark.compileMs,
        solidityVerifierDeployGas: gas.verifierDeployGas,
        adapterDeployGas: gas.adapterDeployGas,
        registryDeployGas: gas.registryDeployGas,
        poolDeployGas: gas.poolDeployGas,
        probeDeployGas: gas.probeDeployGas,
        commitRandomSeedGas: gas.commitRandomSeedGas,
        revealRandomSeedGas: gas.revealRandomSeedGas,
        rewardPoolFundingGas: gas.rewardPoolFundingGas,
        totalClaimGasForPaidRecipients: gas.totalClaimGasForPaidRecipients,
        verificationOutput: benchmark.verifyOutput,
        artifactDir: path.relative(REPO_ROOT, benchmark.outDir),
      };
      rows.push(row);
      artifacts.push({
        N: n,
        circuitArtifactDir: row.artifactDir,
        proofFile: path.relative(REPO_ROOT, benchmark.proofFile),
        publicSignalsFile: path.relative(REPO_ROOT, benchmark.publicFile),
      });
      writeCsv(path.join(RESULTS_DIR, "scaling_reward_layer.csv"), rows);
      writeJson(path.join(RESULTS_DIR, "scaling_reward_layer.json"), {
        generatedAt: new Date().toISOString(),
        benchmark: "reward-layer-only scaling",
        repetitions: REPETITIONS,
        statistic: "single_run",
        ptau,
        rpcUrl: RPC_URL,
        anvil: {
          local: !process.env.REWARD_LAYER_SCALING_RPC_URL,
          gasLimit: 30000000,
          codeSizeLimit: 1000000,
          accounts: 200,
        },
        machine: machineSpecs(),
        interpretation: [
          "The 8-voter full MACI plus reward run remains the end-to-end feasibility measurement.",
          "These rows isolate reward-layer scaling using mocked MACI-derived final reward states.",
          "Larger-N rows do not measure full MACI proving or MACI contract scaling.",
        ],
        rows,
        artifacts,
      });
    }
    console.log(`Wrote ${path.join(RESULTS_DIR, "scaling_reward_layer.csv")}`);
    console.log(`Wrote ${path.join(RESULTS_DIR, "scaling_reward_layer.json")}`);
  } finally {
    fs.rmSync(GENERATED_CONTRACT_DIR, { recursive: true, force: true });
    if (anvil) anvil.kill();
  }
}

main().catch((err) => {
  console.error(err);
  fs.rmSync(GENERATED_CONTRACT_DIR, { recursive: true, force: true });
  process.exit(1);
});
