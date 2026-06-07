"use strict";

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const { ethers } = require("ethers");

const RPC_URL = process.env.RPC_URL || "http://127.0.0.1:8545";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const EXPERIMENT_DATA_DIR = path.resolve(__dirname, "../../experiments/reward-evaluation/data");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function writeCsv(file, rows) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (rows.length === 0) {
    fs.writeFileSync(file, "\n");
    return;
  }
  const headers = Object.keys(rows[0]);
  fs.writeFileSync(
    file,
    `${[
      headers.join(","),
      ...rows.map((row) => headers.map((header) => String(row[header])).join(",")),
    ].join("\n")}\n`,
  );
}

function artifact(contractFile, contractName) {
  const file = path.join(__dirname, `../out/${contractFile}/${contractName}.json`);
  if (!fs.existsSync(file)) {
    throw new Error(`missing artifact ${file}; run forge build first`);
  }
  const data = readJson(file);
  return {
    abi: data.abi,
    bytecode: data.bytecode.object || data.bytecode,
  };
}

async function canConnect(provider) {
  try {
    await provider.getBlockNumber();
    return true;
  } catch {
    return false;
  }
}

async function startAnvilIfNeeded(provider) {
  if (await canConnect(provider)) {
    console.log(`Using existing Anvil RPC: ${RPC_URL}`);
    return null;
  }
  if (process.env.RPC_URL) {
    throw new Error(`RPC_URL is set but unreachable: ${RPC_URL}`);
  }

  console.log("Starting local Anvil on 127.0.0.1:8545");
  const child = spawn("anvil", ["--host", "127.0.0.1", "--port", "8545", "--silent"], {
    stdio: ["ignore", "pipe", "pipe"],
  });

  for (let i = 0; i < 40; i += 1) {
    if (await canConnect(provider)) return child;
    await sleep(250);
  }

  child.kill();
  throw new Error("Anvil did not become ready");
}

async function waitTx(label, tx, metrics) {
  const receipt = await tx.wait();
  console.log(`${label}: tx=${receipt.transactionHash} gas=${receipt.gasUsed.toString()}`);
  if (metrics) {
    metrics.transactions[label] = {
      tx: receipt.transactionHash,
      gas: receipt.gasUsed.toString(),
    };
  }
  return receipt;
}

async function deploy(label, signer, contractFile, contractName, args = [], metrics) {
  const art = artifact(contractFile, contractName);
  const factory = new ethers.ContractFactory(art.abi, art.bytecode, signer);
  const contract = await factory.deploy(...args);
  const receipt = await contract.deployTransaction.wait();
  console.log(`${label}: address=${contract.address} tx=${receipt.transactionHash} gas=${receipt.gasUsed.toString()}`);
  if (metrics) {
    metrics.deployments[label] = {
      address: contract.address,
      tx: receipt.transactionHash,
      gas: receipt.gasUsed.toString(),
    };
  }
  return contract;
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

function firstWinningRecipient(fixture) {
  const winnerIndex = fixture.amounts.findIndex((amount) => BigInt(amount) > 0n);
  if (winnerIndex < 0) {
    throw new Error("fixture has no nonzero payout to claim");
  }
  return {
    index: winnerIndex,
    address: fixture.recipients[winnerIndex],
    amount: fixture.amounts[winnerIndex],
  };
}

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const anvil = await startAnvilIfNeeded(provider);

  try {
    const accounts = await provider.listAccounts();
    if (accounts.length === 0 && !PRIVATE_KEY) {
      throw new Error("no unlocked RPC accounts and PRIVATE_KEY is unset");
    }

    const deployer = PRIVATE_KEY ? new ethers.Wallet(PRIVATE_KEY, provider) : provider.getSigner(accounts[0]);
    const deployerAddress = await deployer.getAddress();
    console.log(`Deployer: ${deployerAddress}`);
    const metrics = {
      generatedAt: new Date().toISOString(),
      rpcUrl: RPC_URL,
      deployer: deployerAddress,
      deployments: {},
      transactions: {},
      context: {},
    };

    const fixture = readJson(path.join(__dirname, "../vectors/v2/reward_proof_fixture.json"));
    const disputeId = ethers.BigNumber.from(fixture.disputeId);
    const finalStateRoot = ethers.BigNumber.from(fixture.finalStateRoot);
    const rewardRandomness = ethers.BigNumber.from(fixture.rewardRandomness);
    const totalPayout = ethers.BigNumber.from(fixture.totalPayout);
    const proof = encodeProof(fixture.proof);

    const verifier = await deploy(
      "Groth16Verifier",
      deployer,
      "RewardGroth16Verifier.sol",
      "Groth16Verifier",
      [],
      metrics,
    );
    const adapter = await deploy(
      "RewardVerifierAdapter",
      deployer,
      "RewardVerifierAdapter.sol",
      "RewardVerifierAdapter",
      [verifier.address],
      metrics,
    );
    const registry = await deploy(
      "FinalStateRegistry",
      deployer,
      "FinalStateRegistry.sol",
      "FinalStateRegistry",
      [],
      metrics,
    );
    const pool = await deploy("IntegratedRewardPool", deployer, "IntegratedRewardPool.sol", "IntegratedRewardPool", [
      adapter.address,
      registry.address,
    ], metrics);

    await waitTx(
      "registerFinalState",
      await registry.registerFinalStateWithRandomness(disputeId, finalStateRoot, 1, rewardRandomness),
      metrics,
    );
    await waitTx("fundDispute", await pool.fundDispute(disputeId, { value: totalPayout }), metrics);
    await waitTx(
      "finalizeRewards",
      await pool.finalizeRewards(
        disputeId,
        fixture.recipients,
        fixture.amounts,
        proof,
        fixture.publicSignals,
      ),
      metrics,
    );

    const winner = firstWinningRecipient(fixture);
    const claimant = winner.address;
    const claimable = await pool.claimable(disputeId, claimant);
    const before = await provider.getBalance(claimant);
    const claimSigner = provider.getSigner(claimant);
    await waitTx("claim", await pool.connect(claimSigner).claim(disputeId), metrics);
    const after = await provider.getBalance(claimant);
    const poolBalanceAfter = await provider.getBalance(pool.address);

    console.log(`disputeId=${disputeId.toString()}`);
    console.log(`finalStateRoot=${finalStateRoot.toString()}`);
    console.log(`rewardRandomness=${rewardRandomness.toString()}`);
    console.log(`winnerIndex=${winner.index}`);
    console.log(`claimant=${claimant}`);
    console.log(`fixtureClaimAmount=${winner.amount}`);
    console.log(`claimableBefore=${claimable.toString()}`);
    console.log(`claimantBalanceBefore=${before.toString()}`);
    console.log(`claimantBalanceAfter=${after.toString()}`);
    console.log(`poolBalanceAfter=${poolBalanceAfter.toString()}`);

    metrics.context = {
      disputeId: disputeId.toString(),
      finalStateRoot: finalStateRoot.toString(),
      rewardRandomness: rewardRandomness.toString(),
      totalPayout: totalPayout.toString(),
      winnerIndex: winner.index,
      claimant,
      fixtureClaimAmount: winner.amount,
      claimableBefore: claimable.toString(),
      claimantBalanceBefore: before.toString(),
      claimantBalanceAfter: after.toString(),
      poolBalanceAfter: poolBalanceAfter.toString(),
    };
    writeJson(path.join(EXPERIMENT_DATA_DIR, "anvil_reward_e2e_latest.json"), metrics);
    writeCsv(path.join(EXPERIMENT_DATA_DIR, "reward_only_gas_breakdown.csv"), [
      { operation: "register", gas: metrics.transactions.registerFinalState.gas },
      { operation: "fund", gas: metrics.transactions.fundDispute.gas },
      { operation: "finalize", gas: metrics.transactions.finalizeRewards.gas },
      { operation: "claim", gas: metrics.transactions.claim.gas },
    ]);
  } finally {
    if (anvil) {
      anvil.kill();
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
