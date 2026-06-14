"use strict";

function toBigInt(value, name = "value") {
  if (typeof value === "bigint") return value;
  if (typeof value === "number" && Number.isInteger(value)) return BigInt(value);
  if (typeof value === "string" && /^-?\d+$/.test(value)) return BigInt(value);
  if (typeof value === "string" && /^0x[0-9a-fA-F]+$/.test(value)) return BigInt(value);
  throw new Error(`${name} must be an integer`);
}

function gcd(a, b) {
  a = a < 0n ? -a : a;
  b = b < 0n ? -b : b;
  while (b !== 0n) {
    const t = a % b;
    a = b;
    b = t;
  }
  return a;
}

function fraction(num, den = 1n) {
  num = toBigInt(num, "num");
  den = toBigInt(den, "den");
  if (den === 0n) throw new Error("zero denominator");
  if (den < 0n) {
    num = -num;
    den = -den;
  }
  const g = gcd(num, den);
  return { num: num / g, den: den / g };
}

function add(a, b) {
  return fraction(a.num * b.den + b.num * a.den, a.den * b.den);
}

function mul(a, b) {
  return fraction(a.num * b.num, a.den * b.den);
}

function div(a, b) {
  if (b.num === 0n) throw new Error("division by zero fraction");
  return fraction(a.num * b.den, a.den * b.num);
}

function cmp(a, b) {
  const left = a.num * b.den;
  const right = b.num * a.den;
  if (left < right) return -1;
  if (left > right) return 1;
  return 0;
}

function floorScaled(a, scale) {
  scale = toBigInt(scale, "scale");
  if (scale <= 0n) throw new Error("scale must be positive");
  return (a.num * scale) / a.den;
}

function assertInputs({ reports, stakes, peerIndices, smoothing, kappa }) {
  if (!Array.isArray(reports) || reports.length === 0) {
    throw new Error("reports must be a non-empty array");
  }
  if (!Array.isArray(stakes) || stakes.length !== reports.length) {
    throw new Error("stakes must have the same length as reports");
  }
  if (!Array.isArray(peerIndices) || peerIndices.length !== reports.length) {
    throw new Error("peerIndices must have the same length as reports");
  }

  reports.forEach((r, i) => {
    if (r !== 0 && r !== 1) throw new Error(`reports[${i}] must be 0 or 1`);
  });
  let positiveStakeCount = 0;
  stakes.forEach((w, i) => {
    const bw = toBigInt(w, `stakes[${i}]`);
    if (bw < 0n) throw new Error(`stakes[${i}] must be non-negative`);
    if (bw > 0n) positiveStakeCount += 1;
  });
  if (positiveStakeCount === 0) throw new Error("at least one stake must be positive");
  peerIndices.forEach((j, i) => {
    if (!Number.isInteger(j) || j < 0 || j >= reports.length) {
      throw new Error(`peerIndices[${i}] out of range`);
    }
    if (j === i) throw new Error(`peerIndices[${i}] must be leave-one-out`);
  });

  if (toBigInt(smoothing, "smoothing") < 0n) {
    throw new Error("smoothing must be non-negative");
  }
  if (toBigInt(kappa, "kappa") < 0n) throw new Error("kappa must be non-negative");
}

function computeLeaveOneOutNormalizers({ reports, stakes, smoothing = 1n }) {
  const n = reports.length;
  const bw = stakes.map((w, i) => toBigInt(w, `stakes[${i}]`));
  const a = toBigInt(smoothing, "smoothing");

  const totalStake = bw.reduce((acc, w) => acc + w, 0n);
  const totalOneStake = bw.reduce((acc, w, i) => acc + w * BigInt(reports[i]), 0n);

  return reports.map((_, i) => {
    const denominator = totalStake - bw[i] + 2n * a;
    const oneNumerator = totalOneStake - bw[i] * BigInt(reports[i]) + a;
    if (denominator <= 0n) throw new Error(`normalizer denominator ${i} is zero`);
    if (oneNumerator < 0n || oneNumerator > denominator) {
      throw new Error(`invalid smoothed normalizer ${i}`);
    }
    return {
      one: fraction(oneNumerator, denominator),
      zero: fraction(denominator - oneNumerator, denominator),
      oneNumerator,
      denominator,
    };
  });
}

function computeRewards({
  reports,
  stakes,
  peerIndices,
  smoothing = 1n,
  kappa = 1n,
  scale = 1_000_000n,
}) {
  assertInputs({ reports, stakes, peerIndices, smoothing, kappa });
  const bw = stakes.map((w, i) => toBigInt(w, `stakes[${i}]`));
  const bk = toBigInt(kappa, "kappa");
  const normalizers = computeLeaveOneOutNormalizers({ reports, stakes: bw, smoothing });

  const rewards = reports.map((r, i) => {
    const peer = peerIndices[i];
    const agreement = reports[i] === reports[peer] ? 1n : 0n;
    if (agreement === 0n || bk === 0n) {
      return {
        exact: fraction(0n),
        scaled: 0n,
        agreement,
        normalizer: r === 1 ? normalizers[i].one : normalizers[i].zero,
      };
    }
    const denom = r === 1 ? normalizers[i].oneNumerator : normalizers[i].denominator - normalizers[i].oneNumerator;
    if (denom <= 0n) throw new Error(`zero report normalizer at index ${i}`);
    const exact = fraction(bk * bw[i] * normalizers[i].denominator, denom);
    return {
      exact,
      scaled: floorScaled(exact, scale),
      agreement,
      normalizer: r === 1 ? normalizers[i].one : normalizers[i].zero,
    };
  });

  return { normalizers, rewards };
}

function computeRewardDivisionWitness({
  reports,
  stakes,
  peerIndices,
  smoothing = 1n,
  kappa = 1n,
  scale = 1_000_000n,
}) {
  assertInputs({ reports, stakes, peerIndices, smoothing, kappa });
  const bw = stakes.map((w, i) => toBigInt(w, `stakes[${i}]`));
  const bk = toBigInt(kappa, "kappa");
  const bs = toBigInt(scale, "scale");
  const normalizers = computeLeaveOneOutNormalizers({ reports, stakes: bw, smoothing });

  return reports.map((r, i) => {
    const peer = peerIndices[i];
    const agreement = reports[i] === reports[peer] ? 1n : 0n;
    const denominator =
      r === 1
        ? normalizers[i].oneNumerator
        : normalizers[i].denominator - normalizers[i].oneNumerator;
    if (denominator <= 0n) throw new Error(`zero report normalizer at index ${i}`);

    const numerator = bk * bw[i] * agreement * normalizers[i].denominator * bs;
    return {
      agreement,
      denominator,
      numerator,
      scaled: numerator / denominator,
      remainder: numerator % denominator,
      normalizer: r === 1 ? normalizers[i].one : normalizers[i].zero,
    };
  });
}

async function poseidonHash(inputs) {
  const { buildPoseidon } = require("circomlibjs");
  if (!poseidonPromise) {
    poseidonPromise = buildPoseidon();
  }
  const poseidon = await poseidonPromise;
  const prepared = inputs.map((value, i) => toBigInt(value, `poseidon input ${i}`));
  return poseidon.F.toObject(poseidon(prepared));
}

function lowBits(value, bits) {
  const b = BigInt(bits);
  if (b <= 0n) throw new Error("bits must be positive");
  return toBigInt(value) & ((1n << b) - 1n);
}

let poseidonPromise;

const LOTTERY_MODE_BASELINE = 0n;
const LOTTERY_MODE_FLOOR_ADJUSTED = 1n;

function normalizeLotteryMode(mode = LOTTERY_MODE_BASELINE) {
  if (typeof mode === "string") {
    if (mode === "baseline" || mode === "reward_correctness") return LOTTERY_MODE_BASELINE;
    if (mode === "floor_adjusted" || mode === "receipt_resistance") {
      return LOTTERY_MODE_FLOOR_ADJUSTED;
    }
  }
  const code = toBigInt(mode, "lotteryMode");
  if (code !== LOTTERY_MODE_BASELINE && code !== LOTTERY_MODE_FLOOR_ADJUSTED) {
    throw new Error("lotteryMode must be 0/baseline or 1/floor_adjusted");
  }
  return code;
}

function lotteryModeLabel(mode) {
  const code = normalizeLotteryMode(mode);
  return code === LOTTERY_MODE_FLOOR_ADJUSTED ? "floor_adjusted" : "baseline";
}

function computeLotteryThreshold({
  scoreScaled,
  rhoTau,
  psiScaled = 0n,
  lotteryMode = LOTTERY_MODE_BASELINE,
  lotteryBits = 32,
}) {
  if (!Number.isInteger(lotteryBits) || lotteryBits <= 0 || lotteryBits > 64) {
    throw new Error("lotteryBits must be an integer in [1, 64]");
  }
  const modeCode = normalizeLotteryMode(lotteryMode);
  const score = toBigInt(scoreScaled, "scoreScaled");
  const brhoTau = toBigInt(rhoTau, "rhoTau");
  const psi = toBigInt(psiScaled, "psiScaled");
  if (score < 0n) throw new Error("scoreScaled must be non-negative");
  if (brhoTau <= 0n) throw new Error("rhoTau must be positive");

  const lotteryScale = 1n << BigInt(lotteryBits);
  if (modeCode === LOTTERY_MODE_BASELINE && psi !== 0n) {
    throw new Error("baseline lottery mode requires psiScaled = 0");
  }
  if (modeCode === LOTTERY_MODE_FLOOR_ADJUSTED && (psi <= 0n || psi * 2n >= lotteryScale)) {
    throw new Error("floor-adjusted mode requires psiScaled in (0, 2^(lotteryBits-1))");
  }

  const rawNumerator = score * lotteryScale;
  const rawThreshold = rawNumerator / brhoTau;
  const thresholdRemainder = rawNumerator % brhoTau;
  if (rawThreshold > lotteryScale) {
    throw new Error("scoreScaled must be at most rhoTau for lottery threshold computation");
  }

  const slopeScaled = lotteryScale - 2n * psi;
  const adjustedNumerator = rawThreshold * slopeScaled;
  const adjustedThreshold = adjustedNumerator / lotteryScale;
  const adjustedThresholdRemainder = adjustedNumerator % lotteryScale;
  const floorAdjustedThreshold = psi + adjustedThreshold;
  const threshold =
    modeCode === LOTTERY_MODE_FLOOR_ADJUSTED ? floorAdjustedThreshold : rawThreshold;
  const rhoEffNumerator = slopeScaled * brhoTau;
  const rhoEff = rhoEffNumerator / lotteryScale;

  return {
    lotteryMode: lotteryModeLabel(modeCode),
    lotteryModeCode: modeCode,
    lotteryScale,
    rhoTau: brhoTau,
    psiScaled: psi,
    rhoEff,
    rhoEffNumerator,
    rawThreshold,
    thresholdRemainder,
    adjustedThreshold,
    adjustedThresholdRemainder,
    threshold,
  };
}

async function computeLotterySeed({ nonces, disputeId, stateRoot }) {
  if (!Array.isArray(nonces) || nonces.length === 0) {
    throw new Error("nonces must be a non-empty array");
  }

  let seed = await poseidonHash([toBigInt(disputeId, "disputeId"), toBigInt(stateRoot, "stateRoot")]);
  for (let i = 0; i < nonces.length; i += 1) {
    seed = await poseidonHash([seed, toBigInt(nonces[i], `nonces[${i}]`)]);
  }
  return seed;
}

async function computeExternalLotterySeed({ disputeId, stateRoot, randomSeed }) {
  return poseidonHash([
    toBigInt(disputeId, "disputeId"),
    toBigInt(stateRoot, "stateRoot"),
    toBigInt(randomSeed, "randomSeed"),
  ]);
}

async function computeLotteryPayouts({
  reports,
  stakes,
  peerIndices,
  nonces,
  disputeId,
  stateRoot,
  smoothing = 1n,
  kappa = 1n,
  scale = 1_000_000n,
  rhoTau,
  lotteryBits = 32,
}) {
  assertInputs({ reports, stakes, peerIndices, smoothing, kappa });
  if (!Array.isArray(nonces) || nonces.length !== reports.length) {
    throw new Error("nonces must have the same length as reports");
  }
  if (!Number.isInteger(lotteryBits) || lotteryBits <= 0 || lotteryBits > 64) {
    throw new Error("lotteryBits must be an integer in [1, 64]");
  }

  const brhoTau = toBigInt(rhoTau, "rhoTau");
  if (brhoTau <= 0n) throw new Error("rhoTau must be positive");

  const rewardWitness = computeRewardDivisionWitness({
    reports,
    stakes,
    peerIndices,
    smoothing,
    kappa,
    scale,
  });
  const lotteryScale = 1n << BigInt(lotteryBits);
  const seed = await computeLotterySeed({ nonces, disputeId, stateRoot });

  const draws = [];
  const drawHashes = [];
  const wins = [];
  const payouts = [];
  for (let i = 0; i < reports.length; i += 1) {
    if (rewardWitness[i].scaled > brhoTau) {
      throw new Error(`rhoTau must cover expected reward at index ${i}`);
    }
    const drawHash = await poseidonHash([seed, BigInt(i)]);
    const draw = lowBits(drawHash, lotteryBits);
    const win = draw * brhoTau < rewardWitness[i].scaled * lotteryScale ? 1n : 0n;
    drawHashes.push(drawHash);
    draws.push(draw);
    wins.push(win);
    payouts.push(win === 1n ? brhoTau : 0n);
  }

  return {
    seed,
    lotteryBits,
    lotteryScale,
    rewardWitness,
    drawHashes,
    draws,
    wins,
    payouts,
  };
}

async function verifyLotteryPayouts(inputs, expectedPayouts) {
  const { payouts } = await computeLotteryPayouts(inputs);
  if (expectedPayouts.length !== payouts.length) return false;
  return payouts.every((payout, i) => payout === toBigInt(expectedPayouts[i], `expected[${i}]`));
}

async function computeFixedBudgetLotteryPayouts({
  reports,
  stakes,
  peerIndices,
  nonces,
  disputeId,
  stateRoot,
  smoothing = 1n,
  kappa = 1n,
  scale = 1_000_000n,
  rhoTau,
  rewardBudget,
  lotteryBits = 32,
}) {
  assertInputs({ reports, stakes, peerIndices, smoothing, kappa });
  if (!Array.isArray(nonces) || nonces.length !== reports.length) {
    throw new Error("nonces must have the same length as reports");
  }
  if (!Number.isInteger(lotteryBits) || lotteryBits <= 0 || lotteryBits > 64) {
    throw new Error("lotteryBits must be an integer in [1, 64]");
  }

  const brhoTau = toBigInt(rhoTau, "rhoTau");
  if (brhoTau <= 0n) throw new Error("rhoTau must be positive");
  const budget = toBigInt(rewardBudget, "rewardBudget");
  if (budget <= 0n) throw new Error("rewardBudget must be positive");

  const rewardWitness = computeRewardDivisionWitness({
    reports,
    stakes,
    peerIndices,
    smoothing,
    kappa,
    scale,
  });
  const lotteryScale = 1n << BigInt(lotteryBits);
  const seed = await computeLotterySeed({ nonces, disputeId, stateRoot });

  const drawHashes = [];
  const draws = [];
  const wins = [];
  const lotteryTentativePayouts = [];
  for (let i = 0; i < reports.length; i += 1) {
    if (rewardWitness[i].scaled > brhoTau) {
      throw new Error(`rhoTau must cover expected reward at index ${i}`);
    }
    const drawHash = await poseidonHash([seed, BigInt(i)]);
    const draw = lowBits(drawHash, lotteryBits);
    const win = draw * brhoTau < rewardWitness[i].scaled * lotteryScale ? 1n : 0n;
    drawHashes.push(drawHash);
    draws.push(draw);
    wins.push(win);
    lotteryTentativePayouts.push(win === 1n ? brhoTau : 0n);
  }

  const allocationBaseline = toBigInt(scale, "scale");
  const stakeValues = stakes.map((stake, i) => toBigInt(stake, `stakes[${i}]`));
  const allocationScores = lotteryTentativePayouts.map(
    (tentative, i) => tentative + (stakeValues[i] > 0n ? allocationBaseline : 0n)
  );
  const totalAllocationScore = allocationScores.reduce((acc, score) => acc + score, 0n);
  if (totalAllocationScore <= 0n) throw new Error("total allocation score must be positive");

  const payouts = [];
  const allocationRemainders = [];
  let allocated = 0n;
  for (let i = 0; i < reports.length - 1; i += 1) {
    const numerator = budget * allocationScores[i];
    const payout = numerator / totalAllocationScore;
    const remainder = numerator % totalAllocationScore;
    payouts.push(payout);
    allocationRemainders.push(remainder);
    allocated += payout;
  }
  payouts.push(budget - allocated);

  return {
    seed,
    lotteryBits,
    lotteryScale,
    rhoTau: brhoTau,
    rewardBudget: budget,
    rewardWitness,
    drawHashes,
    draws,
    wins,
    lotteryTentativePayouts,
    allocationBaseline,
    allocationScores,
    totalAllocationScore,
    allocationRemainders,
    payouts,
  };
}

async function verifyFixedBudgetLotteryPayouts(inputs, expectedPayouts) {
  const { payouts } = await computeFixedBudgetLotteryPayouts(inputs);
  if (expectedPayouts.length !== payouts.length) return false;
  return payouts.every((payout, i) => payout === toBigInt(expectedPayouts[i], `expected[${i}]`));
}

async function computeBernoulliLotteryPayouts({
  reports,
  stakes,
  peerIndices,
  disputeId,
  stateRoot,
  randomSeed,
  smoothing = 1n,
  kappa = 1n,
  scale = 1_000_000n,
  rhoTau,
  psiScaled = 0n,
  lotteryMode = LOTTERY_MODE_BASELINE,
  rewardBudget,
  lotteryBits = 32,
}) {
  assertInputs({ reports, stakes, peerIndices, smoothing, kappa });
  if (!Number.isInteger(lotteryBits) || lotteryBits <= 0 || lotteryBits > 64) {
    throw new Error("lotteryBits must be an integer in [1, 64]");
  }

  const brhoTau = toBigInt(rhoTau, "rhoTau");
  if (brhoTau <= 0n) throw new Error("rhoTau must be positive");
  const modeCode = normalizeLotteryMode(lotteryMode);
  const bpsiScaled = toBigInt(psiScaled, "psiScaled");
  const lotteryScale = 1n << BigInt(lotteryBits);
  const budget = rewardBudget === undefined ? undefined : toBigInt(rewardBudget, "rewardBudget");

  const rewardWitness = computeRewardDivisionWitness({
    reports,
    stakes,
    peerIndices,
    smoothing,
    kappa,
    scale,
  });
  const seed = await computeExternalLotterySeed({ disputeId, stateRoot, randomSeed });

  const rawThresholds = [];
  const thresholdRemainders = [];
  const adjustedThresholds = [];
  const adjustedThresholdRemainders = [];
  const thresholds = [];
  const drawHashes = [];
  const draws = [];
  const wins = [];
  const payouts = [];
  let expectedPayoutNumerator = 0n;
  let rhoEff = 0n;
  let rhoEffNumerator = 0n;
  for (let i = 0; i < reports.length; i += 1) {
    const thresholdData = computeLotteryThreshold({
      scoreScaled: rewardWitness[i].scaled,
      rhoTau: brhoTau,
      psiScaled: bpsiScaled,
      lotteryMode: modeCode,
      lotteryBits,
    });
    const drawHash = await poseidonHash([seed, BigInt(i)]);
    const draw = lowBits(drawHash, lotteryBits);
    const win = draw < thresholdData.threshold ? 1n : 0n;
    rawThresholds.push(thresholdData.rawThreshold);
    thresholdRemainders.push(thresholdData.thresholdRemainder);
    adjustedThresholds.push(thresholdData.adjustedThreshold);
    adjustedThresholdRemainders.push(thresholdData.adjustedThresholdRemainder);
    thresholds.push(thresholdData.threshold);
    drawHashes.push(drawHash);
    draws.push(draw);
    wins.push(win);
    payouts.push(win * brhoTau);
    expectedPayoutNumerator += thresholdData.threshold * brhoTau;
    rhoEff = thresholdData.rhoEff;
    rhoEffNumerator = thresholdData.rhoEffNumerator;
  }

  if (budget !== undefined && expectedPayoutNumerator > budget * lotteryScale) {
    throw new Error("expected payout exceeds rewardBudget");
  }

  return {
    seed,
    lotteryBits,
    lotteryScale,
    rhoTau: brhoTau,
    lotteryMode: lotteryModeLabel(modeCode),
    lotteryModeCode: modeCode,
    psiScaled: bpsiScaled,
    upperThreshold: lotteryScale - bpsiScaled,
    rhoEff,
    rhoEffNumerator,
    rewardBudget: budget,
    rewardWitness,
    rawThresholds,
    thresholdRemainders,
    adjustedThresholds,
    adjustedThresholdRemainders,
    thresholds,
    drawHashes,
    draws,
    wins,
    payouts,
    expectedPayoutNumerator,
  };
}

async function verifyBernoulliLotteryPayouts(inputs, expectedPayouts) {
  const { payouts } = await computeBernoulliLotteryPayouts(inputs);
  if (expectedPayouts.length !== payouts.length) return false;
  return payouts.every((payout, i) => payout === toBigInt(expectedPayouts[i], `expected[${i}]`));
}

function computeFixedBudgetPayouts({
  reports,
  stakes,
  peerIndices,
  smoothing = 1n,
  kappa = 1n,
  scale = 1_000_000n,
  rewardBudget,
}) {
  assertInputs({ reports, stakes, peerIndices, smoothing, kappa });
  const budget = toBigInt(rewardBudget, "rewardBudget");
  if (budget <= 0n) throw new Error("rewardBudget must be positive");

  const rewardWitness = computeRewardDivisionWitness({
    reports,
    stakes,
    peerIndices,
    smoothing,
    kappa,
    scale,
  });
  const allocationBaseline = toBigInt(scale, "scale");
  const stakeValues = stakes.map((stake, i) => toBigInt(stake, `stakes[${i}]`));
  const allocationScores = rewardWitness.map(
    (reward, i) => reward.scaled + (stakeValues[i] > 0n ? allocationBaseline : 0n)
  );
  const totalAllocationScore = allocationScores.reduce((acc, score) => acc + score, 0n);
  if (totalAllocationScore <= 0n) throw new Error("total allocation score must be positive");

  const payouts = [];
  const allocationRemainders = [];
  let allocated = 0n;
  for (let i = 0; i < reports.length - 1; i += 1) {
    const numerator = budget * allocationScores[i];
    const payout = numerator / totalAllocationScore;
    const remainder = numerator % totalAllocationScore;
    payouts.push(payout);
    allocationRemainders.push(remainder);
    allocated += payout;
  }
  payouts.push(budget - allocated);

  return {
    rewardBudget: budget,
    rewardWitness,
    allocationBaseline,
    allocationScores,
    totalAllocationScore,
    allocationRemainders,
    payouts,
  };
}

function verifyFixedBudgetPayouts(inputs, expectedPayouts) {
  const { payouts } = computeFixedBudgetPayouts(inputs);
  if (expectedPayouts.length !== payouts.length) return false;
  return payouts.every((payout, i) => payout === toBigInt(expectedPayouts[i], `expected[${i}]`));
}

async function hashNonceCommitment(nonce) {
  return poseidonHash([toBigInt(nonce, "nonce"), 0n]);
}

async function hashFinalStateLeaf({ maciStateIndex, voterId, report, nonceCommitment, stake, recipient }) {
  if (report !== 0 && report !== 1) throw new Error("report must be 0 or 1");
  const recipientValue = toBigInt(recipient, "recipient");
  if (recipientValue < 0n || recipientValue >= (1n << 160n)) {
    throw new Error("recipient must fit in 160 bits");
  }
  return poseidonHash([
    toBigInt(maciStateIndex, "maciStateIndex"),
    toBigInt(voterId, "voterId"),
    BigInt(report),
    toBigInt(nonceCommitment, "nonceCommitment"),
    toBigInt(stake, "stake"),
    recipientValue,
  ]);
}

async function buildMerkleTree(leaves) {
  if (!Array.isArray(leaves) || leaves.length === 0) {
    throw new Error("leaves must be a non-empty array");
  }
  if ((leaves.length & (leaves.length - 1)) !== 0) {
    throw new Error("leaf count must be a power of two");
  }

  const levels = [leaves.map((leaf, i) => toBigInt(leaf, `leaves[${i}]`))];
  while (levels[levels.length - 1].length > 1) {
    const prev = levels[levels.length - 1];
    const next = [];
    for (let i = 0; i < prev.length; i += 2) {
      next.push(await poseidonHash([prev[i], prev[i + 1]]));
    }
    levels.push(next);
  }
  return { levels, root: levels[levels.length - 1][0] };
}

function getMerklePath(tree, index) {
  if (!tree || !Array.isArray(tree.levels)) throw new Error("invalid tree");
  if (!Number.isInteger(index) || index < 0 || index >= tree.levels[0].length) {
    throw new Error("index out of range");
  }

  const pathElements = [];
  const pathIndices = [];
  let idx = index;
  for (let level = 0; level < tree.levels.length - 1; level += 1) {
    const siblingIndex = idx ^ 1;
    pathElements.push(tree.levels[level][siblingIndex]);
    pathIndices.push(idx & 1);
    idx >>= 1;
  }
  return { pathElements, pathIndices };
}

async function verifyMerklePath({ leaf, root, pathElements, pathIndices }) {
  if (pathElements.length !== pathIndices.length) {
    throw new Error("path length mismatch");
  }
  let node = toBigInt(leaf, "leaf");
  for (let i = 0; i < pathElements.length; i += 1) {
    const sibling = toBigInt(pathElements[i], `pathElements[${i}]`);
    if (pathIndices[i] === 0) {
      node = await poseidonHash([node, sibling]);
    } else if (pathIndices[i] === 1) {
      node = await poseidonHash([sibling, node]);
    } else {
      throw new Error(`pathIndices[${i}] must be 0 or 1`);
    }
  }
  return node === toBigInt(root, "root");
}

async function buildFinalState({ maciStateIndices, voterIds, reports, nonces, nonceCommitments, stakes, recipients }) {
  if (!Array.isArray(maciStateIndices) || maciStateIndices.length !== reports.length) {
    throw new Error("maciStateIndices must have the same length as reports");
  }
  if (!Array.isArray(voterIds) || voterIds.length !== reports.length) {
    throw new Error("voterIds must have the same length as reports");
  }
  if (!Array.isArray(nonceCommitments)) {
    if (!Array.isArray(nonces) || nonces.length !== reports.length) {
      throw new Error("nonces must have the same length as reports when nonceCommitments are omitted");
    }
    nonceCommitments = [];
    for (let i = 0; i < nonces.length; i += 1) {
      nonceCommitments.push(await hashNonceCommitment(nonces[i]));
    }
  }
  if (nonceCommitments.length !== reports.length) {
    throw new Error("nonceCommitments must have the same length as reports");
  }
  if (!Array.isArray(stakes) || stakes.length !== reports.length) {
    throw new Error("stakes must have the same length as reports");
  }
  if (!Array.isArray(recipients) || recipients.length !== reports.length) {
    throw new Error("recipients must have the same length as reports");
  }

  const leaves = [];
  for (let i = 0; i < reports.length; i += 1) {
    leaves.push(
      await hashFinalStateLeaf({
        maciStateIndex: maciStateIndices[i],
        voterId: voterIds[i],
        report: reports[i],
        nonceCommitment: nonceCommitments[i],
        stake: stakes[i],
        recipient: recipients[i],
      }),
    );
  }
  const tree = await buildMerkleTree(leaves);
  const paths = leaves.map((_, i) => getMerklePath(tree, i));
  return { leaves, nonceCommitments, tree, paths, finalStateRoot: tree.root };
}

function verifyScaledPayouts(inputs, expectedScaledPayouts) {
  const { rewards } = computeRewards(inputs);
  if (expectedScaledPayouts.length !== rewards.length) return false;
  return rewards.every((reward, i) => reward.scaled === toBigInt(expectedScaledPayouts[i], `expected[${i}]`));
}

function aggregateFrequency({ outsideOneStake, outsideStake, manipulatorReports, manipulatorStakes }) {
  const R = toBigInt(outsideOneStake, "outsideOneStake");
  const S = toBigInt(outsideStake, "outsideStake");
  const W = manipulatorStakes.reduce((acc, w, i) => {
    const bw = toBigInt(w, `manipulatorStakes[${i}]`);
    if (bw < 0n) throw new Error("manipulator stake must be non-negative");
    return acc + bw;
  }, 0n);
  const X = manipulatorStakes.reduce((acc, w, i) => {
    const r = manipulatorReports[i];
    if (r !== 0 && r !== 1) throw new Error("manipulator report must be binary");
    return acc + toBigInt(w) * BigInt(r);
  }, 0n);
  return fraction(R + X, S + W);
}

function splitLeaveOneOutFrequency({ outsideOneStake, outsideStake, manipulatorReports, manipulatorStakes, accountIndex }) {
  const R = toBigInt(outsideOneStake, "outsideOneStake");
  const S = toBigInt(outsideStake, "outsideStake");
  const W = manipulatorStakes.reduce((acc, w) => acc + toBigInt(w), 0n);
  const X = manipulatorStakes.reduce((acc, w, i) => acc + toBigInt(w) * BigInt(manipulatorReports[i]), 0n);
  const wa = toBigInt(manipulatorStakes[accountIndex], "manipulatorStake");
  const ra = BigInt(manipulatorReports[accountIndex]);
  return fraction(R + X - wa * ra, S + W - wa);
}

function mismatchRatios(q, omega, kappa = 1n) {
  const reports = Object.keys(q);
  const ratios = {};
  for (const r of reports) {
    if (!(r in omega)) throw new Error(`missing omega for report ${r}`);
    ratios[r] = mul(fraction(kappa), div(fraction(q[r]), fraction(omega[r])));
  }
  return ratios;
}

function formatFraction(a) {
  if (a.den === 1n) return a.num.toString();
  return `${a.num}/${a.den}`;
}

module.exports = {
  add,
  aggregateFrequency,
  buildFinalState,
  buildMerkleTree,
  cmp,
  computeFixedBudgetPayouts,
  computeFixedBudgetLotteryPayouts,
  computeBernoulliLotteryPayouts,
  computeLotteryThreshold,
  computeLeaveOneOutNormalizers,
  computeExternalLotterySeed,
  computeLotterySeed,
  computeLotteryPayouts,
  computeRewardDivisionWitness,
  computeRewards,
  div,
  floorScaled,
  formatFraction,
  fraction,
  getMerklePath,
  hashFinalStateLeaf,
  hashNonceCommitment,
  mismatchRatios,
  normalizeLotteryMode,
  lotteryModeLabel,
  LOTTERY_MODE_BASELINE,
  LOTTERY_MODE_FLOOR_ADJUSTED,
  mul,
  poseidonHash,
  splitLeaveOneOutFrequency,
  toBigInt,
  verifyMerklePath,
  verifyFixedBudgetPayouts,
  verifyFixedBudgetLotteryPayouts,
  verifyBernoulliLotteryPayouts,
  verifyLotteryPayouts,
  verifyScaledPayouts,
};
