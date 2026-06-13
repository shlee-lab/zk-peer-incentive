#!/usr/bin/env python3
"""Simulate transcript distinguishing attacks for Bernoulli reward payouts."""

import csv
import math
import os
from pathlib import Path

import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_ROOT / "experiments" / "reward-evaluation" / "data"

N = 8
REPORTS = [1, 0, 1, 1, 0, 0, 1, 0]
STAKES = [10] * N
TARGET_VOTER = int(os.environ.get("ATTACK_TARGET_VOTER", "2"))
SAMPLES = int(os.environ.get("ATTACK_SIM_SAMPLES", "10000"))
K_MAX = int(os.environ.get("ATTACK_K_MAX", "50"))
GAMMAS = [0.02, 0.05, 0.10]
SMOOTHING = 1
KAPPA = int(os.environ.get("ATTACK_KAPPA", "100"))
SCALE = 1000
RHO_TAU = 3_000_000
SEED = int(os.environ.get("ATTACK_SIM_SEED", "20260613"))


def reward_scores(reports):
    total_stake = sum(STAKES)
    total_one_stake = sum(stake * report for stake, report in zip(STAKES, reports))
    scores = []
    for i, report in enumerate(reports):
        d_i = total_stake - STAKES[i] + 2 * SMOOTHING
        n_one = total_one_stake - STAKES[i] * report + SMOOTHING
        denominator = n_one if report == 1 else d_i - n_one
        peer = (i + 1) % N
        agreement = 1 if reports[i] == reports[peer] else 0
        numerator = KAPPA * STAKES[i] * agreement * d_i * SCALE
        scores.append(numerator // denominator)
    return scores


def q_vector(reports, gamma):
    return np.array(
        [min(1.0 - gamma, max(gamma, score / RHO_TAU)) for score in reward_scores(reports)],
        dtype=np.float64,
    )


def classify_advantage(rng, p0, p1, rounds):
    eps = 1e-15
    p0 = np.clip(p0, eps, 1.0 - eps)
    p1 = np.clip(p1, eps, 1.0 - eps)
    log_success = np.log(p1 / p0)
    log_failure = np.log((1.0 - p1) / (1.0 - p0))

    counts0 = rng.binomial(rounds, p0, size=(SAMPLES, N))
    counts1 = rng.binomial(rounds, p1, size=(SAMPLES, N))

    llr0 = (counts0 * log_success + (rounds - counts0) * log_failure).sum(axis=1)
    llr1 = (counts1 * log_success + (rounds - counts1) * log_failure).sum(axis=1)
    accuracy = (np.mean(llr0 < 0.0) + np.mean(llr1 > 0.0)) / 2.0
    return max(0.0, accuracy - 0.5)


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    flipped = REPORTS.copy()
    flipped[TARGET_VOTER] = 1 - flipped[TARGET_VOTER]
    rng = np.random.default_rng(SEED)

    rows = []
    for gamma in GAMMAS:
        p0 = q_vector(REPORTS, gamma)
        p1 = q_vector(flipped, gamma)
        delta = p1 - p0
        eta = float(np.sqrt(np.sum(delta * delta)))
        max_abs_delta = float(np.max(np.abs(delta)))
        for rounds in range(1, K_MAX + 1):
            advantage = classify_advantage(rng, p0, p1, rounds)
            theory = eta * math.sqrt(rounds / (2.0 * gamma * (1.0 - gamma))) / 2.0
            rows.append(
                {
                    "gamma": f"{gamma:.2f}",
                    "targetVoter": TARGET_VOTER,
                    "rounds": rounds,
                    "samplesPerWorld": SAMPLES,
                    "empiricalAdvantage": f"{advantage:.6f}",
                    "theoryAdvantage": f"{min(0.5, theory):.6f}",
                    "uncappedTheoryAdvantage": f"{theory:.6f}",
                    "etaL2": f"{eta:.6f}",
                    "maxAbsCoordinateDelta": f"{max_abs_delta:.6f}",
                    "kappa": KAPPA,
                    "rhoTau": RHO_TAU,
                }
            )

    out = DATA_DIR / "attack_simulation.csv"
    with out.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
