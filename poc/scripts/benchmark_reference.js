"use strict";

const { performance } = require("perf_hooks");
const { computeRewards } = require("../reference/reward_model");

function makeCase(n) {
  const reports = Array.from({ length: n }, (_, i) => (i * 7 + 3) % 5 < 3 ? 1 : 0);
  const stakes = Array.from({ length: n }, (_, i) => BigInt(1 + ((i * 11) % 17)));
  const peerIndices = Array.from({ length: n }, (_, i) => (i + 1) % n);
  return {
    reports,
    stakes,
    peerIndices,
    smoothing: 1n,
    kappa: 100n,
    scale: 1_000_000n,
  };
}

function bench(n, rounds = 500) {
  const input = makeCase(n);
  const start = performance.now();
  let checksum = 0n;
  for (let r = 0; r < rounds; r += 1) {
    const { rewards } = computeRewards(input);
    checksum += rewards.reduce((acc, reward) => acc + reward.scaled, 0n);
  }
  const elapsedMs = performance.now() - start;
  return {
    n,
    rounds,
    totalMs: elapsedMs,
    avgMs: elapsedMs / rounds,
    checksum: checksum.toString(),
  };
}

function run() {
  const sizes = [8, 16, 32, 64, 128];
  console.log("n,rounds,total_ms,avg_ms,checksum");
  for (const n of sizes) {
    const row = bench(n);
    console.log(`${row.n},${row.rounds},${row.totalMs.toFixed(3)},${row.avgMs.toFixed(6)},${row.checksum}`);
  }
}

run();
