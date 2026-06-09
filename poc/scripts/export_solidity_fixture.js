"use strict";

const fs = require("fs");
const path = require("path");

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function uintArray(values) {
  return `[${values.map((value) => `uint256(${value})`).join(", ")}]`;
}

function proofBytes(proof) {
  const a = [proof.pi_a[0], proof.pi_a[1]];
  const b = [
    [proof.pi_b[0][1], proof.pi_b[0][0]],
    [proof.pi_b[1][1], proof.pi_b[1][0]],
  ];
  const c = [proof.pi_c[0], proof.pi_c[1]];

  return [
    "        uint256[2] memory a =",
    `            ${uintArray(a)};`,
    "        uint256[2][2] memory b = [",
    `            ${uintArray(b[0])},`,
    `            ${uintArray(b[1])}`,
    "        ];",
    "        uint256[2] memory c =",
    `            ${uintArray(c)};`,
    "        return abi.encode(a, b, c);",
  ].join("\n");
}

function uintFunction(name, values) {
  return [
    `    function ${name}() internal pure returns (uint256[] memory values) {`,
    `        values = new uint256[](${values.length});`,
    ...values.map((value, i) => `        values[${i}] = ${value};`),
    "    }",
  ].join("\n");
}

function recipientAddresses(count) {
  const addresses = [
    // Anvil deterministic accounts after the deployer, so any paid recipient can claim in E2E.
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
    "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
    "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
    "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
  ];
  if (count > addresses.length) {
    throw new Error(`only ${addresses.length} fixture recipient addresses are configured`);
  }
  return addresses.slice(0, count);
}

function addressFunction(count) {
  const addresses = recipientAddresses(count);
  return [
    "    function recipients() internal pure returns (address[] memory values) {",
    `        values = new address[](${count});`,
    ...addresses.map((address, i) => `        values[${i}] = ${address};`),
    "    }",
  ].join("\n");
}

function main() {
  const [proofFile, publicFile, vectorFile, outputFile] = process.argv.slice(2);
  if (!proofFile || !publicFile || !vectorFile || !outputFile) {
    throw new Error(
      "usage: node scripts/export_solidity_fixture.js <proof.json> <public.json> <vector.json> <output.sol> [output.fixture.json]",
    );
  }

  const proof = readJson(proofFile);
  const publicSignals = readJson(publicFile);
  const vector = readJson(vectorFile);
  const amounts = publicSignals.slice(0, vector.payouts.length);
  const recipients = recipientAddresses(amounts.length);
  const totalPayout = amounts.reduce((acc, value) => acc + BigInt(value), 0n);

  const source = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RewardProofFixture {
    uint256 internal constant PUBLIC_SIGNAL_COUNT = ${publicSignals.length};
    uint256 internal constant PAYOUT_COUNT = ${amounts.length};
    uint256 internal constant TOTAL_PAYOUT = ${totalPayout.toString()};

${uintFunction("publicSignals", publicSignals)}

${uintFunction("amounts", amounts)}

${addressFunction(amounts.length)}

    function proof() internal pure returns (bytes memory) {
${proofBytes(proof)}
    }
}
`;

  fs.mkdirSync(path.dirname(outputFile), { recursive: true });
  fs.writeFileSync(outputFile, source);
  console.log(`Wrote ${outputFile}`);

  const jsonOutputFile = process.argv[6];
  if (jsonOutputFile) {
    const jsonFixture = {
      proof,
      publicSignals,
      amounts,
      recipients,
      payoutCount: amounts.length,
      totalPayout: totalPayout.toString(),
      disputeId: publicSignals[28],
      finalStateRoot: publicSignals[29],
    };
    fs.mkdirSync(path.dirname(jsonOutputFile), { recursive: true });
    fs.writeFileSync(jsonOutputFile, `${JSON.stringify(jsonFixture, null, 2)}\n`);
    console.log(`Wrote ${jsonOutputFile}`);
  }
}

main();
