#!/usr/bin/env python3
"""Synthetic public-transcript privacy audit for the reward lottery."""

import csv
import json
import math
import os
import random
from pathlib import Path

try:
    import matplotlib.pyplot as plt
except ModuleNotFoundError as err:
    raise SystemExit(
        "Missing matplotlib. From poc/, run:\n"
        "  python3 -m venv .venv\n"
        "  . .venv/bin/activate\n"
        "  pip install -r requirements.txt"
    ) from err


REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "experiments" / "reward-evaluation"
DATA_DIR = OUT_DIR / "data"
FIG_DIR = OUT_DIR / "figures"

N = 8
LOTTERY_SCALE = 2**32
RHO = 3_000_000
SMOOTHING = 1
KAPPA = 100
SCALE = 1_000
STAKES = [10] * N
MODES = [("baseline", 0.0), ("floor_adjusted", 0.05), ("floor_adjusted", 0.10), ("floor_adjusted", 0.20), ("floor_adjusted", 0.30)]
PI_VALUES = [0.05, 0.10, 0.20, 0.50]
SEED = int(os.environ.get("PRIVACY_AUDIT_SEED", "20260614"))
INSTANCES = int(os.environ.get("PRIVACY_AUDIT_INSTANCES", "2000"))
BOOTSTRAPS = int(os.environ.get("PRIVACY_AUDIT_BOOTSTRAPS", "200"))

INK = "#1f2937"
MUTED = "#6b7280"
GRID = "#e5e7eb"
COLORS = {
    "baseline": "#1f77b4",
    "0.05": "#2ca02c",
    "0.10": "#9467bd",
    "0.20": "#ff7f0e",
    "0.30": "#d62728",
}


def configure_style():
    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": ["Nimbus Roman", "Times New Roman", "Liberation Serif", "DejaVu Serif"],
            "mathtext.fontset": "stix",
            "font.size": 8.5,
            "axes.labelsize": 8.5,
            "axes.titlesize": 9,
            "axes.linewidth": 0.8,
            "axes.edgecolor": INK,
            "xtick.labelsize": 7.5,
            "ytick.labelsize": 7.5,
            "legend.fontsize": 7.0,
            "legend.frameon": False,
            "grid.color": GRID,
            "grid.linewidth": 0.55,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "savefig.bbox": "tight",
            "savefig.pad_inches": 0.08,
        }
    )


def save_csv(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("\n", encoding="utf-8")
        return
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def save_json(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")


def save_figure(fig, stem):
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(FIG_DIR / f"{stem}.pdf")
    fig.savefig(FIG_DIR / f"{stem}.png", dpi=300)
    plt.close(fig)
    print(f"Wrote {FIG_DIR / (stem + '.pdf')}")
    print(f"Wrote {FIG_DIR / (stem + '.png')}")


def read_latest_measurements():
    proof_shape = {"constraints": 30164, "public_inputs": 34, "private_inputs": 112}
    proof_file = DATA_DIR / "proof_shape.csv"
    if proof_file.exists():
        with proof_file.open(newline="", encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                if row["metric"] in proof_shape:
                    proof_shape[row["metric"]] = int(row["value"])

    proof_time_file = REPO_ROOT / "poc" / "artifacts" / "v2" / "reward_proof_time_ms.txt"
    latest_file = DATA_DIR / "full_maci_reward_anvil_latest.json"
    reward_only_file = DATA_DIR / "anvil_reward_e2e_latest.json"
    proof_time_ms = 2630
    finalize_gas = 584313
    claim_gas = 30729
    if proof_time_file.exists():
        proof_time_ms = int(proof_time_file.read_text(encoding="utf-8").strip())
    if reward_only_file.exists():
        latest = json.loads(reward_only_file.read_text(encoding="utf-8"))
        txs = latest.get("transactions", {})
        finalize_gas = int(txs.get("finalizeRewards", {}).get("gas", finalize_gas))
        claim_gas = int(txs.get("claim", {}).get("gas", claim_gas))
    if latest_file.exists():
        latest = json.loads(latest_file.read_text(encoding="utf-8"))
        proof_time_ms = int(latest.get("proofTimesMs", {}).get("reward", proof_time_ms))
        gas = latest.get("rewardGas", {})
        finalize_gas = int(gas.get("finalizeRewards", finalize_gas))
        claim_gas = int(gas.get("claim", claim_gas))

    return {
        **proof_shape,
        "proof_time_ms": proof_time_ms,
        "finalize_gas": finalize_gas,
        "claim_gas": claim_gas,
    }


def mode_label(mode, psi):
    return "baseline" if mode == "baseline" else f"psi={psi:.2f}"


def psi_scaled(psi):
    return int(math.floor(psi * LOTTERY_SCALE))


def rho_eff(psi):
    return int(math.floor((1.0 - 2.0 * psi) * RHO))


def generate_reports(rng):
    base = rng.uniform(0.62, 0.82)
    copy_prob = rng.uniform(0.70, 0.90)
    reports = [1 if rng.random() < base else 0]
    for _ in range(1, N):
        if rng.random() < copy_prob:
            reports.append(reports[-1])
        else:
            reports.append(1 if rng.random() < base else 0)
    return reports, base


def shortcut_reports(rng, base):
    return [1 if rng.random() < base else 0 for _ in range(N)]


def scores(reports):
    total_stake = sum(STAKES)
    total_one_stake = sum(stake * report for stake, report in zip(STAKES, reports))
    out = []
    for i, report in enumerate(reports):
        peer = (i + 1) % N
        d_i = total_stake - STAKES[i] + 2 * SMOOTHING
        n_i = total_one_stake - STAKES[i] * report + SMOOTHING
        denom = n_i if report == 1 else d_i - n_i
        agreement = 1 if report == reports[peer] else 0
        if denom <= 0 or agreement == 0:
            out.append(0)
        else:
            raw = (KAPPA * STAKES[i] * agreement * d_i * SCALE) // denom
            out.append(min(raw, RHO))
    return out


def probabilities(score_values, mode, psi):
    values = []
    for score in score_values:
        raw = min(max(score / RHO, 0.0), 1.0)
        if mode == "baseline":
            values.append(raw)
        else:
            values.append(psi + (1.0 - 2.0 * psi) * raw)
    return values


def simulate_payouts(rng, q_values):
    wins = [1 if rng.random() < q else 0 for q in q_values]
    return wins, [win * RHO for win in wins]


def exposure_for_reports(reports, mode, psi):
    base_q = probabilities(scores(reports), mode, psi)
    rows = []
    for i in range(N):
        flipped = list(reports)
        flipped[i] = 1 - flipped[i]
        flipped_q = probabilities(scores(flipped), mode, psi)
        changed = [j for j, (a, b) in enumerate(zip(base_q, flipped_q)) if abs(a - b) > 1e-12]
        rows.append((len(changed), changed))
    return rows


def auc(scores_values, labels):
    pairs = sorted(zip(scores_values, labels), key=lambda x: x[0])
    n_pos = sum(labels)
    n_neg = len(labels) - n_pos
    if n_pos == 0 or n_neg == 0:
        return 0.5
    rank_sum = 0.0
    i = 0
    rank = 1
    while i < len(pairs):
        j = i
        while j < len(pairs) and pairs[j][0] == pairs[i][0]:
            j += 1
        avg_rank = (rank + rank + (j - i) - 1) / 2.0
        rank_sum += avg_rank * sum(label for _, label in pairs[i:j])
        rank += j - i
        i = j
    return (rank_sum - n_pos * (n_pos + 1) / 2.0) / (n_pos * n_neg)


def best_threshold_accuracy(values, labels):
    def high_value_predicts_one(vals):
        pairs = sorted(zip(vals, labels), key=lambda item: item[0])
        n = len(pairs)
        total_pos = sum(labels)
        total_neg = n - total_pos
        if total_pos == 0 or total_neg == 0:
            return 0.5
        below_pos = 0
        below_neg = 0
        best = 0.5
        i = 0
        while i < n:
            j = i
            group_pos = 0
            while j < n and pairs[j][0] == pairs[i][0]:
                group_pos += pairs[j][1]
                j += 1
            group_count = j - i
            below_pos += group_pos
            below_neg += group_count - group_pos
            true_positive = total_pos - below_pos
            true_negative = below_neg
            balanced = 0.5 * (true_positive / total_pos + true_negative / total_neg)
            best = max(best, balanced)
            i = j
        return best

    if not values:
        return 0.0
    return max(high_value_predicts_one(values), high_value_predicts_one([-value for value in values]))


def tv_from_rows(rows):
    by_label = {0: [row for row in rows if row["hiddenReport"] == 0], 1: [row for row in rows if row["hiddenReport"] == 1]}
    if not by_label[0] or not by_label[1]:
        return 0.0
    p0 = sum(float(row["q"]) for row in by_label[0]) / len(by_label[0])
    p1 = sum(float(row["q"]) for row in by_label[1]) / len(by_label[1])
    return abs(p1 - p0)


def confidence_interval(values):
    if not values:
        return (0.0, 0.0)
    values = sorted(values)
    lo = values[int(0.025 * (len(values) - 1))]
    hi = values[int(0.975 * (len(values) - 1))]
    return lo, hi


def bootstrap_metrics(rows, rng):
    tv_values = []
    payout_acc_values = []
    transcript_acc_values = []
    n = len(rows)
    for _ in range(BOOTSTRAPS):
        sample = [rows[rng.randrange(n)] for _ in range(n)]
        labels = [row["hiddenReport"] for row in sample]
        payout_values = [row["payout"] for row in sample]
        transcript_values = [row["transcriptScore"] for row in sample]
        tv_values.append(tv_from_rows(sample))
        payout_acc_values.append(best_threshold_accuracy(payout_values, labels))
        transcript_acc_values.append(best_threshold_accuracy(transcript_values, labels))
    return {
        "tv_ci": confidence_interval(tv_values),
        "payout_acc_ci": confidence_interval(payout_acc_values),
        "transcript_acc_ci": confidence_interval(transcript_acc_values),
    }


def compute_summary(sample_rows, gap_rows):
    rng = random.Random(SEED + 99)
    summary = []
    bribe_rows = []
    grouped = {}
    for row in sample_rows:
        grouped.setdefault(row["mode"], []).append(row)

    for label, rows in grouped.items():
        labels = [row["hiddenReport"] for row in rows]
        payout_values = [row["payout"] for row in rows]
        transcript_values = [row["transcriptScore"] for row in rows]
        report0 = [row for row in rows if row["hiddenReport"] == 0]
        report1 = [row for row in rows if row["hiddenReport"] == 1]
        p_win_0 = sum(float(row["q"]) for row in report0) / len(report0)
        p_win_1 = sum(float(row["q"]) for row in report1) / len(report1)
        empirical_eta = abs(p_win_1 - p_win_0)
        payout_acc = best_threshold_accuracy(payout_values, labels)
        transcript_acc = best_threshold_accuracy(transcript_values, labels)
        raw_auc = auc(transcript_values, labels)
        transcript_auc = max(raw_auc, 1.0 - raw_auc)
        gap_values = [row["expectedRewardGap"] for row in gap_rows if row["mode"] == label]
        gap = sum(gap_values) / len(gap_values)
        empirical_delta = gap / RHO
        boot = bootstrap_metrics(rows, rng)
        max_d = max(row["D_i"] for row in rows)
        avg_d = sum(row["D_i"] for row in rows) / len(rows)
        first = rows[0]
        summary.append(
            {
                "mode": label,
                "psi": f"{first['psi']:.2f}",
                "rho": RHO,
                "rhoEff": first["rhoEff"],
                "constraints": first["constraints"],
                "publicInputs": first["publicInputs"],
                "privateInputs": first["privateInputs"],
                "proofTimeMs": first["proofTimeMs"],
                "finalizeGas": first["finalizeGas"],
                "claimGas": first["claimGas"],
                "pWinReport0": f"{p_win_0:.6f}",
                "pWinReport1": f"{p_win_1:.6f}",
                "empiricalEta": f"{empirical_eta:.6f}",
                "empiricalEtaCiLow": f"{boot['tv_ci'][0]:.6f}",
                "empiricalEtaCiHigh": f"{boot['tv_ci'][1]:.6f}",
                "payoutThresholdAccuracy": f"{payout_acc:.6f}",
                "payoutAccuracyCiLow": f"{boot['payout_acc_ci'][0]:.6f}",
                "payoutAccuracyCiHigh": f"{boot['payout_acc_ci'][1]:.6f}",
                "transcriptAccuracy": f"{transcript_acc:.6f}",
                "transcriptAccuracyCiLow": f"{boot['transcript_acc_ci'][0]:.6f}",
                "transcriptAccuracyCiHigh": f"{boot['transcript_acc_ci'][1]:.6f}",
                "transcriptAuc": f"{transcript_auc:.6f}",
                "expectedRewardGap": f"{gap:.6f}",
                "empiricalDelta": f"{empirical_delta:.6f}",
                "maxD": max_d,
                "avgD": f"{avg_d:.6f}",
            }
        )

        base_rate = sum(labels) / len(labels)
        for selector in ("payout", "transcriptScore"):
            ranked = sorted(rows, key=lambda row: row[selector], reverse=True)
            for pi in PI_VALUES:
                k = max(1, int(math.ceil(pi * len(ranked))))
                selected = ranked[:k]
                precision = sum(row["hiddenReport"] for row in selected) / len(selected)
                bribe_rows.append(
                    {
                        "mode": label,
                        "psi": f"{first['psi']:.2f}",
                        "selector": selector,
                        "selectedShare": f"{pi:.2f}",
                        "selectedCount": len(selected),
                        "targetReport": 1,
                        "baseRate": f"{base_rate:.6f}",
                        "precision": f"{precision:.6f}",
                        "enrichment": f"{(precision / base_rate) if base_rate > 0 else 0.0:.6f}",
                    }
                )
    return summary, bribe_rows


def set_common_axes(ax):
    ax.grid(True, axis="y")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.set_axisbelow(True)


def plot_outputs(summary_rows, bribe_rows, exposure_summary):
    configure_style()
    ordered = ["baseline", "psi=0.05", "psi=0.10", "psi=0.20", "psi=0.30"]
    by_mode = {row["mode"]: row for row in summary_rows}
    xs = list(range(len(ordered)))
    labels = ["0" if mode == "baseline" else mode.split("=")[1] for mode in ordered]

    fig, ax = plt.subplots(figsize=(3.6, 2.35), constrained_layout=True)
    width = 0.36
    ax.bar([x - width / 2 for x in xs], [float(by_mode[m]["pWinReport0"]) for m in ordered], width, label="report 0", color=COLORS["baseline"])
    ax.bar([x + width / 2 for x in xs], [float(by_mode[m]["pWinReport1"]) for m in ordered], width, label="report 1", color=COLORS["0.20"])
    ax.set_xticks(xs, labels)
    ax.set_xlabel(r"Floor parameter $\psi$")
    ax.set_ylabel("Win probability")
    ax.legend(ncols=2, loc="upper center")
    set_common_axes(ax)
    save_figure(fig, "privacy_payout_distributions")

    fig, ax = plt.subplots(figsize=(3.55, 2.35), constrained_layout=True)
    ax.plot(labels, [float(by_mode[m]["payoutThresholdAccuracy"]) for m in ordered], marker="o", label="payout only", color=COLORS["baseline"])
    ax.plot(labels, [float(by_mode[m]["transcriptAccuracy"]) for m in ordered], marker="s", label="public transcript", color=COLORS["0.10"])
    ax.axhline(0.5, color=MUTED, linestyle="--", linewidth=0.9, label="chance")
    ax.set_xlabel(r"Floor parameter $\psi$")
    ax.set_ylabel("Best classifier accuracy")
    ax.set_ylim(0.49, 0.56)
    ax.legend(loc="upper right")
    set_common_axes(ax)
    save_figure(fig, "privacy_inference_accuracy")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(5.25, 2.25), constrained_layout=True)
    ax1.plot(labels, [float(by_mode[m]["expectedRewardGap"]) / 1_000_000 for m in ordered], marker="o", color=COLORS["0.20"], label="reward gap")
    ax1.set_xlabel(r"Floor parameter $\psi$")
    ax1.set_ylabel(r"Expected gap ($\times 10^6$)")
    ax1.set_title("Incentive gap")
    set_common_axes(ax1)
    ax2.plot(labels, [float(by_mode[m]["rhoEff"]) / 1_000_000 for m in ordered], marker="s", color=COLORS["0.10"], label=r"$\rho_{eff}$")
    ax2.set_xlabel(r"Floor parameter $\psi$")
    ax2.set_ylabel(r"$\rho_{eff}$ ($\times 10^6$)")
    ax2.set_title("Reward capacity")
    set_common_axes(ax2)
    save_figure(fig, "privacy_incentive_gap")

    fig, ax = plt.subplots(figsize=(3.35, 2.35), constrained_layout=True)
    ax.plot([float(by_mode[m]["empiricalEta"]) for m in ordered], [float(by_mode[m]["empiricalDelta"]) for m in ordered], marker="o", color=COLORS["0.30"])
    offsets = {
        "baseline": (4, -2),
        "psi=0.05": (4, -4),
        "psi=0.10": (4, -2),
        "psi=0.20": (4, -2),
        "psi=0.30": (4, 1),
    }
    for mode in ordered:
        ax.annotate(
            "0" if mode == "baseline" else mode.split("=")[1],
            (float(by_mode[mode]["empiricalEta"]), float(by_mode[mode]["empiricalDelta"])),
            xytext=offsets[mode],
            textcoords="offset points",
            fontsize=6.8,
        )
    ax.set_xlabel(r"Empirical $\eta$ (TV)")
    ax.set_ylabel(r"Empirical $\delta$ (gap / $\rho$)")
    set_common_axes(ax)
    save_figure(fig, "privacy_empirical_frontier")

    fig, ax = plt.subplots(figsize=(3.55, 2.35), constrained_layout=True)
    for mode in ("baseline", "psi=0.10", "psi=0.30"):
        rows = [row for row in bribe_rows if row["mode"] == mode and row["selector"] == "transcriptScore"]
        rows.sort(key=lambda row: float(row["selectedShare"]))
        ax.plot([float(row["selectedShare"]) for row in rows], [float(row["enrichment"]) for row in rows], marker="o", label=mode, color=COLORS["baseline" if mode == "baseline" else mode.split("=")[1]])
    ax.axhline(1.0, color=MUTED, linestyle="--", linewidth=1.0)
    ax.set_xticks(PI_VALUES, [f"{value:.2f}" for value in PI_VALUES])
    ax.set_xlabel(r"Selected group share $\pi$")
    ax.set_ylabel("Target-report enrichment")
    ax.legend()
    set_common_axes(ax)
    save_figure(fig, "privacy_selective_bribery")

    fig, ax = plt.subplots(figsize=(3.55, 2.35), constrained_layout=True)
    ax.bar(labels, [float(exposure_summary[m]["avgD"]) for m in ordered], color=COLORS["baseline"])
    max_values = [float(exposure_summary[m]["maxD"]) for m in ordered]
    ax.plot(labels, max_values, color=COLORS["0.30"], marker="o")
    ax.annotate(
        "max",
        (len(labels) - 1, max_values[-1]),
        xytext=(8, -2),
        textcoords="offset points",
        fontsize=7.0,
    )
    ax.set_xlabel(r"Floor parameter $\psi$")
    ax.set_ylabel(r"Exposure count $D_i$")
    set_common_axes(ax)
    save_figure(fig, "privacy_exposure_report")


def main():
    rng = random.Random(SEED)
    measurements = read_latest_measurements()
    sample_rows = []
    exposure_rows = []
    gap_rows = []

    for instance_id in range(INSTANCES):
        reports, base_rate = generate_reports(rng)
        shortcut = shortcut_reports(rng, base_rate)
        truth_scores = scores(reports)
        shortcut_scores = scores(shortcut)
        for mode, psi in MODES:
            label = mode_label(mode, psi)
            truth_q = probabilities(truth_scores, mode, psi)
            shortcut_q = probabilities(shortcut_scores, mode, psi)
            wins, payouts = simulate_payouts(rng, truth_q)
            total_payout = sum(payouts)
            d_rows = exposure_for_reports(reports, mode, psi)
            expected_truth = sum(q * RHO for q in truth_q) / N
            expected_shortcut = sum(q * RHO for q in shortcut_q) / N
            gap_rows.append(
                {
                    "mode": label,
                    "instanceId": instance_id,
                    "expectedTruthfulReward": f"{expected_truth:.6f}",
                    "expectedShortcutReward": f"{expected_shortcut:.6f}",
                    "expectedRewardGap": expected_truth - expected_shortcut,
                }
            )
            for i in range(N):
                predecessor = (i - 1) % N
                peer = (i + 1) % N
                transcript_score = (
                    payouts[i] / RHO
                    + 0.35 * payouts[predecessor] / RHO
                    + 0.35 * payouts[peer] / RHO
                    + 0.10 * total_payout / (N * RHO)
                )
                d_i, changed = d_rows[i]
                sample_rows.append(
                    {
                        "mode": label,
                        "lotteryMode": mode,
                        "instanceId": instance_id,
                        "reporterIndex": i,
                        "hiddenReport": reports[i],
                        "payout": payouts[i],
                        "claimableAmount": payouts[i],
                        "lotteryOutcome": wins[i],
                        "scoreX": truth_scores[i],
                        "q": f"{truth_q[i]:.9f}",
                        "psi": psi,
                        "psiScaled": psi_scaled(psi),
                        "rho": RHO,
                        "rhoEff": rho_eff(psi),
                        "D_i": d_i,
                        "publicTranscriptFields": "payoutVector;claimableBalances;publicInputs;finalizationTx;rewardState",
                        "transcriptTotalPayout": total_payout,
                        "transcriptPayoutVector": ";".join(str(payout) for payout in payouts),
                        "transcriptScore": transcript_score,
                        "proofTimeMs": measurements["proof_time_ms"],
                        "finalizeGas": measurements["finalize_gas"],
                        "claimGas": measurements["claim_gas"],
                        "constraints": measurements["constraints"],
                        "publicInputs": measurements["public_inputs"],
                        "privateInputs": measurements["private_inputs"],
                    }
                )
                exposure_rows.append(
                    {
                        "mode": label,
                        "lotteryMode": mode,
                        "psi": f"{psi:.2f}",
                        "instanceId": instance_id,
                        "reporterIndex": i,
                        "D_i": d_i,
                        "changedPayoutCoordinates": ";".join(str(index) for index in changed),
                        "countedTranscriptFields": "public payout coordinates; claimable balances mirror payouts; public root/id/seed changes are documented but not counted as payout coordinates",
                    }
                )

    summary_rows, bribe_rows = compute_summary(sample_rows, gap_rows)
    exposure_summary = {}
    for mode in [mode_label(mode, psi) for mode, psi in MODES]:
        values = [row["D_i"] for row in exposure_rows if row["mode"] == mode]
        exposure_summary[mode] = {
            "mode": mode,
            "maxD": max(values),
            "avgD": f"{sum(values) / len(values):.6f}",
            "minD": min(values),
        }

    save_csv(DATA_DIR / "privacy_audit_samples.csv", sample_rows)
    save_csv(DATA_DIR / "privacy_audit_summary.csv", summary_rows)
    save_csv(DATA_DIR / "privacy_audit_exposure.csv", exposure_rows)
    save_csv(DATA_DIR / "privacy_audit_exposure_summary.csv", list(exposure_summary.values()))
    save_csv(DATA_DIR / "privacy_audit_selective_bribery.csv", bribe_rows)
    save_csv(DATA_DIR / "privacy_audit_incentive_gap.csv", gap_rows)
    save_json(
        DATA_DIR / "privacy_audit_manifest.json",
        {
            "seed": SEED,
            "instances": INSTANCES,
            "reportersPerInstance": N,
            "modes": [{"mode": mode_label(mode, psi), "psi": psi, "rhoEff": rho_eff(psi)} for mode, psi in MODES],
            "measurements": measurements,
            "transcriptFields": [
                "payout vector",
                "claimable balances",
                "verifier public inputs",
                "reward finalization transaction",
                "registered reward state",
            ],
            "note": "Hidden reports are logged only by this synthetic audit harness; production reports remain private.",
        },
    )
    plot_outputs(summary_rows, bribe_rows, exposure_summary)
    print(f"Wrote privacy audit data to {DATA_DIR}")


if __name__ == "__main__":
    main()
