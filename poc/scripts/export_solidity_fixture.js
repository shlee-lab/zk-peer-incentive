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

function addressFunction(count) {
  return [
    "    function recipients() internal pure returns (address[] memory values) {",
    `        values = new address[](${count});`,
    ...Array.from(
      { length: count },
      (_, i) => `        values[${i}] = address(uint160(${0x1000 + i}));`,
    ),
    "    }",
  ].join("\n");
}

function main() {
  const [proofFile, publicFile, vectorFile, outputFile] = process.argv.slice(2);
  if (!proofFile || !publicFile || !vectorFile || !outputFile) {
    throw new Error(
      "usage: node scripts/export_solidity_fixture.js <proof.json> <public.json> <vector.json> <output.sol>",
    );
  }

  const proof = readJson(proofFile);
  const publicSignals = readJson(publicFile);
  const vector = readJson(vectorFile);
  const amounts = publicSignals.slice(0, vector.payouts.length);
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
}

main();

