"use strict";

const fs = require("fs");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

const projectRoot = path.resolve(__dirname, "../..");
const pocRoot = path.join(projectRoot, "poc");
const maciRepo = path.resolve(process.env.MACI_REPO || "/tmp/maci-official");
const nodeVersion = process.env.MACI_NODE_VERSION || "20.20.2";
const useAnvil = process.env.FULL_MACI_NETWORK === "anvil" || process.env.FULL_MACI_ANVIL === "1";
const anvilPort = process.env.FULL_MACI_ANVIL_PORT || "8556";
const anvilRpcUrl = process.env.FULL_MACI_ANVIL_RPC_URL || `http://127.0.0.1:${anvilPort}`;
const anvilMnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";
const generatedTestPath = path.join(
  maciRepo,
  "packages/testing/ts/__tests__/zk_peer_reward_sidecar.generated.test.ts",
);
const testingHardhatConfigPath = path.join(maciRepo, "packages/testing/hardhat.config.ts");

function shellQuote(value) {
  return `'${String(value).replace(/'/g, "'\\''")}'`;
}

function requirePath(target, message) {
  if (!fs.existsSync(target)) {
    throw new Error(`${message}: ${target}`);
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function testingHardhatConfigSource() {
  return `import "@nomicfoundation/hardhat-toolbox";

import type { HardhatUserConfig } from "hardhat/types";

const WALLET_MNEMONIC = ${JSON.stringify(anvilMnemonic)};
const GAS_LIMIT = 30_000_000;

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      url: ${JSON.stringify(anvilRpcUrl)},
      gas: GAS_LIMIT,
      blockGasLimit: GAS_LIMIT,
      gasPrice: "auto",
      accounts: { count: 101, mnemonic: WALLET_MNEMONIC },
      loggingEnabled: false,
    },
    hardhat: {
      gas: GAS_LIMIT,
      blockGasLimit: GAS_LIMIT,
      accounts: { count: 101, mnemonic: WALLET_MNEMONIC },
      mining: {
        auto: true,
        interval: 100,
      },
    },
  },
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true,
        },
      },
    },
  },
  paths: {
    sources: "./node_modules/@maci-protocol/sdk/node_modules/@maci-protocol/contracts/contracts",
    artifacts: "./node_modules/@maci-protocol/sdk/node_modules/@maci-protocol/contracts/artifacts",
  },
};

export default config;
`;
}

async function waitForAnvilReady() {
  for (let i = 0; i < 80; i += 1) {
    const result = spawnSync("cast", ["block-number", "--rpc-url", anvilRpcUrl], {
      encoding: "utf8",
      stdio: "pipe",
    });
    if (result.status === 0) {
      return;
    }
    await sleep(250);
  }
  throw new Error(`Anvil did not become ready at ${anvilRpcUrl}`);
}

async function startAnvil() {
  console.log(`Starting Anvil for full MACI E2E at ${anvilRpcUrl}`);
  const child = spawn(
    "anvil",
    [
      "--host",
      "127.0.0.1",
      "--port",
      anvilPort,
      "--chain-id",
      "31337",
      "--mnemonic",
      anvilMnemonic,
      "--accounts",
      "101",
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

  child.stderr.on("data", (data) => {
    process.stderr.write(data);
  });

  try {
    await waitForAnvilReady();
  } catch (err) {
    child.kill();
    throw err;
  }

  return child;
}

function generatedTestSource() {
  return `import { getSigners } from "@maci-protocol/contracts";
import { EMode, VOTE_OPTION_TREE_ARITY } from "@maci-protocol/core";
import { Keypair } from "@maci-protocol/domainobjs";
import {
  DEFAULT_IVCP_DATA,
  DEFAULT_SG_DATA,
  DEFAULT_INITIAL_VOICE_CREDITS,
  coordinatorKeypair,
  coordinatorPrivateKey,
  deployArgs,
  deployPollArgs,
  mergeSignupsArgs,
  pollDuration,
  proveOnChainArgs,
  testPollJoiningWasmPath,
  testPollJoiningWitnessPath,
  testPollJoiningZkeyPath,
  testProcessMessageZkeyPath,
  testProcessMessagesWasmPath,
  testProcessMessagesWitnessDatPath,
  testProcessMessagesWitnessPath,
  testProofsDirPath,
  testRapidsnarkPath,
  testTallyFilePath,
  testTallyVotesWasmPath,
  testTallyVotesWitnessDatPath,
  testTallyVotesWitnessPath,
  testTallyVotesZkeyPath,
  timeTravelArgs,
  verifyingKeysArgs,
  verifyArgs,
} from "../constants";
import {
  deployConstantInitialVoiceCreditProxy,
  deployConstantInitialVoiceCreditProxyFactory,
  deployFreeForAllSignUpPolicy,
  deployMaci,
  deployPoll,
  generateMaciState,
  generateProofs,
  getBlockTimestamp,
  isArm,
  joinPoll,
  mergeSignups,
  proveOnChain,
  publish,
  setVerifyingKeys,
  signup,
  timeTravel,
  verify,
  type IGenerateProofsArgs,
  type IMaciContracts,
} from "@maci-protocol/sdk";
import { ethers, type Signer } from "ethers";
import { execFileSync } from "child_process";
import { expect } from "chai";
import fs from "fs";
import path from "path";

const PROJECT_ROOT = ${JSON.stringify(projectRoot)};
const POC_ROOT = path.join(PROJECT_ROOT, "poc");
const OUTPUT_ROOT = process.env.FULL_MACI_REWARD_OUTPUT_ROOT || path.join(POC_ROOT, "artifacts/full_maci_reward");
const EVALUATION_LATEST_FILE = path.join(PROJECT_ROOT, "experiments/reward-evaluation/data/full_maci_reward_anvil_latest.json");
const FIELD_PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const REPORTS = [1, 0, 1, 1, 0, 0, 1, 0];
const STAKES = ["10", "10", "10", "10", "10", "10", "10", "10"];
const rewardDeployments: Record<string, { address: string; tx?: string; gas?: string }> = {};
const rewardTransactions: Record<string, { tx: string; gas: string }> = {};

function deterministicCommandSalt(index: number): bigint {
  return BigInt(ethers.id(\`zk-peer-full-maci-command-salt-\${index}\`)) % FIELD_PRIME;
}

function readJson(file: string): any {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function artifact(contractFile: string, contractName: string): { abi: any; bytecode: string } {
  const file = path.join(POC_ROOT, "out", contractFile, \`\${contractName}.json\`);
  if (!fs.existsSync(file)) {
    throw new Error(\`missing artifact \${file}; run forge build in poc/ first\`);
  }
  const data = readJson(file);
  return {
    abi: data.abi,
    bytecode: data.bytecode.object || data.bytecode,
  };
}

async function deployRewardContract(label: string, signer: Signer, contractFile: string, contractName: string, args: any[] = []) {
  const art = artifact(contractFile, contractName);
  const factory = new ethers.ContractFactory(art.abi, art.bytecode, signer);
  const contract = await factory.deploy(...args);
  const deployment = await contract.deploymentTransaction()?.wait();
  const address = await contract.getAddress();
  console.log(\`\${label}: address=\${address} tx=\${deployment?.hash} gas=\${deployment?.gasUsed.toString()}\`);
  rewardDeployments[label] = {
    address,
    tx: deployment?.hash,
    gas: deployment?.gasUsed.toString(),
  };
  return contract;
}

async function waitTx(label: string, tx: any) {
  const receipt = await tx.wait();
  console.log(\`\${label}: tx=\${receipt.hash} gas=\${receipt.gasUsed.toString()}\`);
  rewardTransactions[label] = {
    tx: receipt.hash,
    gas: receipt.gasUsed.toString(),
  };
  return receipt;
}

function encodeProof(proof: any): string {
  const a = [proof.pi_a[0], proof.pi_a[1]];
  const b = [
    [proof.pi_b[0][1], proof.pi_b[0][0]],
    [proof.pi_b[1][1], proof.pi_b[1][0]],
  ];
  const c = [proof.pi_c[0], proof.pi_c[1]];
  return ethers.AbiCoder.defaultAbiCoder().encode(
    ["uint256[2]", "uint256[2][2]", "uint256[2]"],
    [a, b, c],
  );
}

function resetMaciOutputs() {
  fs.rmSync(testProofsDirPath, { recursive: true, force: true });
  fs.mkdirSync(testProofsDirPath, { recursive: true });
  fs.rmSync(testTallyFilePath, { force: true });
  fs.rmSync("./backup", { recursive: true, force: true });
  fs.rmSync(OUTPUT_ROOT, { recursive: true, force: true });
  fs.mkdirSync(OUTPUT_ROOT, { recursive: true });
}

async function deployMaciStack(signer: Signer): Promise<IMaciContracts> {
  const constantInitialVoiceCreditProxyFactory = await deployConstantInitialVoiceCreditProxyFactory(signer, true);
  const initialVoiceCreditProxy = await deployConstantInitialVoiceCreditProxy(
    { amount: DEFAULT_INITIAL_VOICE_CREDITS },
    constantInitialVoiceCreditProxyFactory,
    signer,
  );
  const initialVoiceCreditProxyContractAddress = await initialVoiceCreditProxy.getAddress();

  const [signupPolicy, , signupPolicyFactory, signupCheckerFactory] = await deployFreeForAllSignUpPolicy(
    {},
    signer,
    true,
  );
  const signupPolicyContractAddress = await signupPolicy.getAddress();
  const [pollPolicy] = await deployFreeForAllSignUpPolicy(
    { policy: signupPolicyFactory, checker: signupCheckerFactory },
    signer,
    true,
  );
  const pollPolicyContractAddress = await pollPolicy.getAddress();

  const maciAddresses = await deployMaci({
    ...deployArgs,
    signer,
    signupPolicyAddress: signupPolicyContractAddress,
  });

  await setVerifyingKeys({
    ...(await verifyingKeysArgs(signer)),
    verifyingKeysRegistryAddress: maciAddresses.verifyingKeysRegistryContractAddress,
  });

  const startDate = await getBlockTimestamp(signer);
  await deployPoll({
    ...deployPollArgs,
    signer,
    pollStartTimestamp: startDate,
    pollEndTimestamp: startDate + pollDuration,
    relayers: [await signer.getAddress()],
    maciAddress: maciAddresses.maciContractAddress,
    policyContractAddress: pollPolicyContractAddress,
    initialVoiceCreditProxyContractAddress,
  });

  return maciAddresses;
}

function generateRewardProof(sidecarFile: string, rewardOutDir: string, fixtureFile: string) {
  execFileSync(
    "node",
    [
      path.join(POC_ROOT, "scripts/build_sidecar_reward_artifacts.js"),
      "--sidecar",
      sidecarFile,
      "--out-dir",
      rewardOutDir,
      "--fixture",
      fixtureFile,
    ],
    { cwd: POC_ROOT, stdio: "inherit" },
  );
}

describe("full MACI plus reward sidecar E2E", function test() {
  this.timeout(900000);

  it("runs official MACI tally proofs, derives reward sidecar state, finalizes, and claims", async () => {
    resetMaciOutputs();
    const useWasm = isArm();
    const signers = await getSigners();
    const [signer, ...userSigners] = signers;
    const users = Array.from({ length: 8 }, () => new Keypair());
    const commandSalts: bigint[] = [];
    const network = await signer.provider!.getNetwork();
    console.log(\`executionNetworkChainId=\${network.chainId.toString()}\`);
    console.log(\`rewardOutputRoot=\${OUTPUT_ROOT}\`);

    const generateProofsArgs: Omit<IGenerateProofsArgs, "maciAddress" | "signer"> = {
      outputDir: testProofsDirPath,
      tallyFile: testTallyFilePath,
      voteTallyZkey: testTallyVotesZkeyPath,
      messageProcessorZkey: testProcessMessageZkeyPath,
      pollId: 0n,
      rapidsnark: testRapidsnarkPath,
      messageProcessorWitnessGenerator: testProcessMessagesWitnessPath,
      messageProcessorWitnessDatFile: testProcessMessagesWitnessDatPath,
      voteTallyWitnessGenerator: testTallyVotesWitnessPath,
      voteTallyWitnessDatFile: testTallyVotesWitnessDatPath,
      coordinatorPrivateKey,
      messageProcessorWasm: testProcessMessagesWasmPath,
      voteTallyWasm: testTallyVotesWasmPath,
      useWasm,
      mode: EMode.QV,
    };

    const maciAddresses = await deployMaciStack(signer);
    console.log(\`MACI: address=\${maciAddresses.maciContractAddress}\`);

    for (let i = 0; i < users.length; i += 1) {
      await signup({
        maciAddress: maciAddresses.maciContractAddress,
        maciPublicKey: users[i].publicKey.serialize(),
        sgData: DEFAULT_SG_DATA,
        signer: userSigners[i],
      });
    }

    for (let i = 0; i < users.length; i += 1) {
      await joinPoll({
        maciAddress: maciAddresses.maciContractAddress,
        privateKey: users[i].privateKey.serialize(),
        pollId: 0n,
        pollJoiningZkey: testPollJoiningZkeyPath,
        useWasm,
        pollJoiningWasm: testPollJoiningWasmPath,
        pollWitnessGenerator: testPollJoiningWitnessPath,
        rapidsnark: testRapidsnarkPath,
        sgDataArg: DEFAULT_SG_DATA,
        ivcpDataArg: DEFAULT_IVCP_DATA,
        signer: userSigners[i],
      });
    }

    for (let i = 0; i < users.length; i += 1) {
      const commandSalt = deterministicCommandSalt(i);
      commandSalts.push(commandSalt);
      await publish({
        maciAddress: maciAddresses.maciContractAddress,
        publicKey: users[i].publicKey.serialize(),
        stateIndex: BigInt(i + 1),
        voteOptionIndex: BigInt(REPORTS[i]),
        nonce: 1n,
        pollId: 0n,
        newVoteWeight: 9n,
        salt: commandSalt,
        privateKey: users[i].privateKey.serialize(),
        signer,
      });
    }

    const maciProofStarted = Date.now();
    await timeTravel({ ...timeTravelArgs, signer });
    await mergeSignups({ ...mergeSignupsArgs, maciAddress: maciAddresses.maciContractAddress, signer });
    const { tallyData } = await generateProofs({
      ...generateProofsArgs,
      signer,
      maciAddress: maciAddresses.maciContractAddress,
    });
    await proveOnChain({ ...proveOnChainArgs, maciAddress: maciAddresses.maciContractAddress, signer });
    await verify({ ...(await verifyArgs(signer)), tallyData, maciAddress: tallyData.maci });
    const maciProofMs = Date.now() - maciProofStarted;

    const maciState = await generateMaciState({
      pollId: 0n,
      maciAddress: maciAddresses.maciContractAddress,
      coordinatorPrivateKey,
      signer,
    });
    const poll = maciState.polls.get(0n);
    if (!poll) {
      throw new Error("poll 0 missing from reconstructed MACI state");
    }
    while (poll.hasUnprocessedMessages()) {
      poll.processMessages(0n);
    }
    while (poll.hasUntalliedBallots()) {
      poll.tallyVotes();
    }

    const extractedReports = REPORTS.map((_, i) => (poll.ballots[i + 1].votes[1] > 0n ? 1 : 0));
    expect(extractedReports).to.deep.eq(REPORTS);

    const recipients = await Promise.all(REPORTS.map((_, i) => userSigners[i].getAddress()));
    const sidecar = {
      pollId: "0",
      disputeId: "0",
      reports: extractedReports,
      maciStateIndices: REPORTS.map((_, i) => String(i + 1)),
      voterIds: REPORTS.map((_, i) => poll.pollStateLeaves[i + 1].hash().toString()),
      stakes: STAKES,
      recipients,
      nonces: commandSalts.map((value) => value.toString()),
      nonceSource: "maci-vote-command-salt",
      smoothing: "1",
      kappa: "100",
      scale: "1000",
      rhoTau: "3000000",
      rewardBudget: "24000000",
      nonceLabel: "full-maci-reward-sidecar",
    };
    const sidecarFile = path.join(OUTPUT_ROOT, "sidecar_input.json");
    const rewardOutDir = path.join(OUTPUT_ROOT, "reward");
    const fixtureFile = path.join(rewardOutDir, "reward_proof_fixture.json");
    fs.writeFileSync(sidecarFile, JSON.stringify(sidecar, null, 2));
    generateRewardProof(sidecarFile, rewardOutDir, fixtureFile);
    const fixture = readJson(fixtureFile);
    const rewardSummary = readJson(path.join(rewardOutDir, "summary.json"));

    const disputeId = BigInt(fixture.disputeId);
    const finalRewardStateRoot = BigInt(fixture.finalStateRoot);
    const totalPayout = BigInt(fixture.totalPayout);
    expect(totalPayout).to.be.greaterThan(0n);

    const rewardVerifier = await deployRewardContract(
      "RewardGroth16Verifier",
      signer,
      "RewardGroth16Verifier.sol",
      "Groth16Verifier",
    );
    const rewardVerifierAddress = await rewardVerifier.getAddress();
    const adapter = await deployRewardContract(
      "RewardVerifierAdapter",
      signer,
      "RewardVerifierAdapter.sol",
      "RewardVerifierAdapter",
      [rewardVerifierAddress],
    );
    const adapterAddress = await adapter.getAddress();
    const registry = await deployRewardContract("FinalStateRegistry", signer, "FinalStateRegistry.sol", "FinalStateRegistry");
    const registryAddress = await registry.getAddress();
    const pool = await deployRewardContract(
      "IntegratedRewardPool",
      signer,
      "IntegratedRewardPool.sol",
      "IntegratedRewardPool",
      [adapterAddress, registryAddress],
    );
    const poolAddress = await pool.getAddress();

    await waitTx(
      "reward.commitRandomSeed",
      await registry.commitRandomSeed(disputeId, fixture.seedCommitment),
    );
    await waitTx(
      "reward.registerFinalState",
      await registry.registerFinalState(disputeId, finalRewardStateRoot, BigInt(tallyData.results.tally[1])),
    );
    await waitTx(
      "reward.revealRandomSeed",
      await registry.revealRandomSeed(disputeId, fixture.seedPreimage, fixture.seedSalt),
    );
    const maxExposure = BigInt(fixture.payoutCount) * BigInt(fixture.publicSignals[27]);
    await waitTx("reward.fundDispute", await pool.fundDispute(disputeId, { value: maxExposure }));
    await waitTx(
      "reward.finalizeRewards",
      await pool.finalizeRewards(
        disputeId,
        fixture.recipients,
        fixture.amounts,
        encodeProof(fixture.proof),
        fixture.publicSignals,
      ),
    );

    const claimIndex = fixture.amounts.findIndex((amount: string) => BigInt(amount) > 0n);
    expect(claimIndex).to.be.greaterThanOrEqual(0);
    const claimant = await userSigners[claimIndex].getAddress();
    expect(claimant).to.eq(fixture.recipients[claimIndex]);
    const claimable = await pool.claimable(disputeId, claimant);
    await waitTx("reward.claim", await pool.connect(userSigners[claimIndex]).claim(disputeId));
    const poolBalanceAfterSampleClaim = await signer.provider!.getBalance(poolAddress);
    const evaluationRecord = {
      chainId: network.chainId.toString(),
      maciAddress: maciAddresses.maciContractAddress,
      maciTally: {
        option0: tallyData.results.tally[0],
        option1: tallyData.results.tally[1],
        totalSpentVoiceCredits: tallyData.totalSpentVoiceCredits.spent,
      },
      reports: extractedReports,
      stakeDesign: "uniform",
      stakes: STAKES,
      rewardMode: "coordinate-wise Bernoulli lottery",
      rhoTau: "3000000",
      gammaScaled: fixture.publicSignals[31],
      lotteryWins: rewardSummary.lotteryWins,
      finalRewardStateRoot: fixture.finalStateRoot,
      rewardNonceSource: "maci-vote-command-salt",
      rewardBudget: sidecar.rewardBudget,
      maxExposure: maxExposure.toString(),
      randomSeed: fixture.randomSeed,
      payouts: fixture.amounts,
      paidRecipientIndices: fixture.amounts
        .map((amount: string, index: number) => (BigInt(amount) > 0n ? index : -1))
        .filter((index: number) => index >= 0),
      totalPayout: fixture.totalPayout,
      sampleClaimIndex: claimIndex,
      sampleClaimant: claimant,
      sampleClaimableBefore: claimable.toString(),
      poolBalanceAfterSampleClaim: poolBalanceAfterSampleClaim.toString(),
      proofTimesMs: {
        maci: maciProofMs,
        reward: fixture.proofGenerationMs,
      },
      rewardGas: {
        commitRandomSeed: Number(rewardTransactions["reward.commitRandomSeed"].gas),
        registerFinalState: Number(rewardTransactions["reward.registerFinalState"].gas),
        revealRandomSeed: Number(rewardTransactions["reward.revealRandomSeed"].gas),
        fundDispute: Number(rewardTransactions["reward.fundDispute"].gas),
        finalizeRewards: Number(rewardTransactions["reward.finalizeRewards"].gas),
        claim: Number(rewardTransactions["reward.claim"].gas),
      },
      rewardDeployGas: Object.fromEntries(
        Object.entries(rewardDeployments).map(([label, value]) => [label, Number(value.gas)]),
      ),
      rewardTxHashes: {
        ...Object.fromEntries(
          Object.entries(rewardDeployments).map(([label, value]) => [\`\${label}Deploy\`, value.tx]),
        ),
        ...Object.fromEntries(Object.entries(rewardTransactions).map(([label, value]) => [label, value.tx])),
      },
    };
    fs.mkdirSync(path.dirname(EVALUATION_LATEST_FILE), { recursive: true });
    fs.writeFileSync(EVALUATION_LATEST_FILE, JSON.stringify(evaluationRecord, null, 2));

    console.log(\`maciProofMs=\${maciProofMs}\`);
    console.log(\`rewardProofMs=\${fixture.proofGenerationMs}\`);
    console.log(\`maciTally0=\${tallyData.results.tally[0]} maciTally1=\${tallyData.results.tally[1]}\`);
    console.log(\`reports=\${extractedReports.join(",")}\`);
    console.log(\`finalRewardStateRoot=\${fixture.finalStateRoot}\`);
    console.log(\`rewardNonceSource=maci-vote-command-salt\`);
    console.log(\`rewardPool=\${poolAddress}\`);
    console.log(\`claimIndex=\${claimIndex}\`);
    console.log(\`claimant=\${claimant}\`);
    console.log(\`claimableBefore=\${claimable.toString()}\`);
    console.log(\`poolBalanceAfter=\${poolBalanceAfterSampleClaim.toString()}\`);
    console.log(\`evaluationLatest=\${EVALUATION_LATEST_FILE}\`);
  });
});
`;
}

async function main() {
  requirePath(maciRepo, "MACI_REPO does not exist");
  requirePath(path.join(maciRepo, "pnpm-lock.yaml"), "MACI_REPO is not an official MACI checkout");
  requirePath(path.join(pocRoot, "out/RewardGroth16Verifier.sol/Groth16Verifier.json"), "missing reward verifier artifact; run forge build");
  requirePath(path.join(pocRoot, "artifacts/v2/reward_check_final.zkey"), "missing reward zkey; run the v2 proof setup first");

  fs.writeFileSync(generatedTestPath, generatedTestSource());
  console.log(`Wrote ${generatedTestPath}`);

  let anvilChild = null;
  let originalTestingHardhatConfig = null;
  if (useAnvil) {
    requirePath(testingHardhatConfigPath, "missing official MACI testing hardhat config");
    originalTestingHardhatConfig = fs.readFileSync(testingHardhatConfigPath, "utf8");
    fs.writeFileSync(testingHardhatConfigPath, testingHardhatConfigSource());
    console.log(`Patched ${testingHardhatConfigPath} for Anvil localhost`);
  }

  const command = [
    `if [ -s "$HOME/.nvm/nvm.sh" ]; then source "$HOME/.nvm/nvm.sh" && nvm use ${shellQuote(nodeVersion)}; fi`,
    "node -v",
    `pnpm --filter @maci-protocol/testing exec ts-mocha --exit ${shellQuote(generatedTestPath)}`,
  ].join(" && ");

  try {
    if (useAnvil) {
      const anvilCheck = spawnSync("bash", ["-lc", "command -v anvil"], { encoding: "utf8" });
      if (anvilCheck.status !== 0) {
        throw new Error("anvil binary not found in PATH");
      }
      anvilChild = await startAnvil();
    }

    const env = {
      ...process.env,
      FULL_MACI_REWARD_OUTPUT_ROOT: useAnvil
        ? path.join(pocRoot, "artifacts/full_maci_reward_anvil")
        : path.join(pocRoot, "artifacts/full_maci_reward"),
    };
    if (useAnvil) {
      env.HARDHAT_NETWORK = "localhost";
    }

    const result = spawnSync("bash", ["-lc", command], {
      cwd: maciRepo,
      env,
      stdio: "inherit",
    });

    if (result.status !== 0) {
      throw new Error("full MACI reward E2E failed");
    }
  } finally {
    if (anvilChild) {
      anvilChild.kill();
    }
    if (originalTestingHardhatConfig !== null) {
      fs.writeFileSync(testingHardhatConfigPath, originalTestingHardhatConfig);
      console.log(`Restored ${testingHardhatConfigPath}`);
    }
  }
}

try {
  Promise.resolve(main()).catch((err) => {
    console.error(err);
    process.exit(1);
  });
} catch (err) {
  console.error(err);
  process.exit(1);
}
