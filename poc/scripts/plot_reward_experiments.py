#!/usr/bin/env python3

import csv
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    from matplotlib.patches import Patch
    from matplotlib.ticker import FuncFormatter, LogLocator, NullFormatter
except ModuleNotFoundError as err:
    raise SystemExit(
        "Missing matplotlib. From poc/, run:\n"
        "  python3 -m venv .venv\n"
        "  . .venv/bin/activate\n"
        "  pip install -r requirements.txt\n"
        "Then rerun npm run experiments:reward-plots."
    ) from err


REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "experiments" / "reward-evaluation"
DATA_DIR = OUT_DIR / "data"
FIG_DIR = OUT_DIR / "figures"

MILLION = 1_000_000.0
THOUSAND = 1_000.0
INK = "#1f2937"
MUTED = "#6b7280"
GRID = "#e5e7eb"
COLORS = {
    "blue": "#1f77b4",
    "orange": "#ff7f0e",
    "green": "#2ca02c",
    "red": "#d62728",
    "purple": "#9467bd",
    "gray": "#7f7f7f",
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
            "xtick.color": INK,
            "ytick.color": INK,
            "legend.fontsize": 7.4,
            "legend.frameon": False,
            "lines.linewidth": 1.7,
            "lines.markersize": 4.0,
            "grid.color": GRID,
            "grid.linewidth": 0.55,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "savefig.bbox": "tight",
            "savefig.pad_inches": 0.08,
        }
    )


def read_csv(name):
    with open(DATA_DIR / name, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def read_csv_if_exists(name):
    file = DATA_DIR / name
    if not file.exists():
        return []
    with open(file, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def save(fig, stem):
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    pdf = FIG_DIR / f"{stem}.pdf"
    png = FIG_DIR / f"{stem}.png"
    fig.savefig(pdf, bbox_inches="tight", pad_inches=0.08)
    fig.savefig(png, dpi=300, bbox_inches="tight", pad_inches=0.08)
    plt.close(fig)
    print(f"Wrote {pdf}")
    print(f"Wrote {png}")


def set_common_axes(ax):
    ax.grid(True, axis="y")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.tick_params(axis="both", length=3.0, width=0.7)
    ax.set_axisbelow(True)


def millions(x, _pos):
    return f"{x / MILLION:.1f}"


def thousands(x, _pos):
    return f"{x / THOUSAND:.0f}"


def percent(x, _pos):
    return f"{100 * x:.0f}%"


def compact_amount(x, _pos=None):
    if x >= MILLION:
        return f"{x / MILLION:.1f}M"
    if x >= THOUSAND:
        return f"{x / THOUSAND:.0f}k"
    return f"{x:.0f}"


def plot_reward_sensitivity():
    rows = read_csv("reward_sensitivity.csv")
    profiles = [
        ("maci_anvil_reports", "MACI-derived", COLORS["blue"], "o"),
        ("one_sided", "one-sided", COLORS["green"], "s"),
        ("consensus", "consensus", COLORS["purple"], "^"),
        ("alternating", "no-match", COLORS["gray"], "D"),
    ]

    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    for profile, label, color, marker in profiles:
        points = [
            (float(row["kappa"]), float(row["maxPayoutShare"]))
            for row in rows
            if row["profile"] == profile and row["smoothing"] == "1"
        ]
        points.sort()
        xs = [x for x, _ in points]
        ys = [y for _, y in points]
        ax.plot(xs, ys, color=color, marker=marker, label=label)

    set_common_axes(ax)
    ax.set_xlabel(r"Reward scale $\kappa$", labelpad=4)
    ax.set_ylabel(r"Largest payout share $\max_i P_i/B$", labelpad=4)
    ax.yaxis.set_major_formatter(FuncFormatter(percent))
    ax.set_xticks([0, 25, 50, 100])
    ax.set_xlim(-3, 105)
    ax.set_ylim(0.10, 0.78)
    ax.legend(
        ncol=2,
        loc="lower left",
        bbox_to_anchor=(0.0, 1.01),
        handlelength=1.7,
        columnspacing=1.0,
        borderaxespad=0.0,
    )
    save(fig, "reward_sensitivity")


def plot_lottery_confidence():
    rows = read_csv_if_exists("lottery_confidence.csv")
    if not rows:
        return

    profiles = [
        ("maci_anvil_reports", "MACI-derived", COLORS["blue"], "o"),
        ("one_sided", "one-sided", COLORS["green"], "s"),
        ("consensus", "consensus", COLORS["purple"], "^"),
        ("alternating", "no-match", COLORS["gray"], "D"),
    ]

    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    for profile, label, color, marker in profiles:
        points = [
            (
                float(row["kappa"]),
                float(row["maxPayoutShareMean"]),
                float(row["maxPayoutShareCiLow"]),
                float(row["maxPayoutShareCiHigh"]),
            )
            for row in rows
            if row["profile"] == profile and row["smoothing"] == "1"
        ]
        points.sort()
        xs = [x for x, _, _, _ in points]
        mean = [y for _, y, _, _ in points]
        p05 = [y for _, _, y, _ in points]
        p95 = [y for _, _, _, y in points]
        if profile == "maci_anvil_reports":
            lower = [max(0.0, m - lo) for m, lo in zip(mean, p05)]
            upper = [max(0.0, hi - m) for m, hi in zip(mean, p95)]
            ax.errorbar(
                xs,
                mean,
                yerr=[lower, upper],
                color=color,
                marker=marker,
                capsize=2.3,
                elinewidth=0.85,
                label=label,
            )
        else:
            ax.plot(xs, mean, color=color, marker=marker, label=label)

    set_common_axes(ax)
    ax.set_xlabel(r"Reward scale $\kappa$", labelpad=4)
    ax.set_ylabel(r"Largest payout share $\max_i P_i/B$", labelpad=4)
    ax.yaxis.set_major_formatter(FuncFormatter(percent))
    ax.set_xticks([0, 25, 50, 100])
    ax.set_xlim(-3, 105)
    ax.set_ylim(0.08, 1.02)
    ax.text(
        0.98,
        0.92,
        "error bars: MACI 95% CI",
        transform=ax.transAxes,
        ha="right",
        va="top",
        fontsize=6.6,
        color=MUTED,
    )
    ax.legend(
        ncol=2,
        loc="lower left",
        bbox_to_anchor=(0.0, 1.01),
        handlelength=1.7,
        columnspacing=1.0,
        borderaxespad=0.0,
    )
    save(fig, "lottery_confidence")


def plot_budget_allocation():
    rows = read_csv("budget_allocation.csv")
    labels = [str(int(row["voterIndex"])) for row in rows]
    payouts = [float(row["payout"]) for row in rows]
    lottery_wins = [int(row["lotteryWin"]) for row in rows]
    colors = [COLORS["blue"] if win == 1 else COLORS["gray"] for win in lottery_wins]
    total = sum(payouts)
    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    bars = ax.bar(range(len(labels)), payouts, color=colors, width=0.62)
    set_common_axes(ax)
    ax.set_xlabel("Voter index", labelpad=4)
    ax.set_ylabel(r"Fixed-budget payout $P_i$ (log)", labelpad=4)
    ax.set_yscale("log")
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=5))
    ax.yaxis.set_major_formatter(FuncFormatter(compact_amount))
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.set_xticks(range(len(labels)), labels)
    ax.set_ylim(max(1.0, min(payouts) * 0.45), max(payouts) * 2.0)

    for bar, value in zip(bars, payouts):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            value * 1.16,
            compact_amount(value),
            ha="center",
            va="bottom",
            fontsize=7.0,
            color=INK,
        )
    ax.text(
        0.98,
        0.94,
        rf"$\sum_i P_i={total / MILLION:.1f}\times 10^6$",
        transform=ax.transAxes,
        ha="right",
        va="top",
        color=MUTED,
        fontsize=7.2,
    )
    ax.legend(
        handles=[
            Patch(facecolor=COLORS["blue"], label="lottery winner"),
            Patch(facecolor=COLORS["gray"], label="not selected"),
        ],
        loc="lower left",
        bbox_to_anchor=(0.0, 1.01),
        ncol=2,
        handlelength=1.2,
        columnspacing=1.0,
        borderaxespad=0.0,
    )
    save(fig, "budget_allocation")


def plot_e2e_overhead():
    rows = read_csv_if_exists("e2e_overhead.csv")
    if not rows:
        return

    proof_rows = [row for row in rows if row["section"] == "proof_time" and row["value"]]
    gas_rows = [row for row in rows if row["section"] == "reward_gas" and row["value"]]
    if not proof_rows or not gas_rows:
        return

    fig, axes = plt.subplots(1, 2, figsize=(6.15, 2.35), constrained_layout=True)
    ax = axes[0]
    proof_labels = ["MACI", "Reward"]
    proof_values = [float(row["value"]) for row in proof_rows]
    ax.bar(range(len(proof_values)), proof_values, color=[COLORS["gray"], COLORS["blue"]], width=0.58)
    set_common_axes(ax)
    ax.set_xticks(range(len(proof_labels)), proof_labels)
    ax.set_ylabel("Proof time (s)", labelpad=4)
    ax.set_yscale("log")
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=4))
    ax.yaxis.set_minor_formatter(NullFormatter())
    for index, value in enumerate(proof_values):
        ax.text(index, value * 1.14, f"{value:.1f}s", ha="center", va="bottom", fontsize=6.8, color=INK)

    ax = axes[1]
    gas_label_map = {
        "Commit seed": "Commit",
        "Register root": "Register",
        "Reveal seed": "Reveal",
        "Fund pool": "Fund",
        "Verify + finalize": "Finalize",
        "Claim": "Claim",
    }
    gas_labels = [gas_label_map.get(row["metric"], row["metric"]) for row in gas_rows]
    gas_values = [float(row["value"]) for row in gas_rows]
    gas_colors = [COLORS["purple"], COLORS["blue"], COLORS["purple"], COLORS["gray"], COLORS["green"], COLORS["orange"]]
    ax.bar(range(len(gas_values)), gas_values, color=gas_colors[: len(gas_values)], width=0.58)
    set_common_axes(ax)
    ax.set_xticks(range(len(gas_labels)), gas_labels, rotation=32, ha="right")
    ax.set_ylabel(r"Reward gas ($\times 10^3$)", labelpad=4)
    ax.yaxis.set_major_formatter(FuncFormatter(thousands))
    ax.set_ylim(0, max(gas_values) * 1.25)
    for index, value in enumerate(gas_values):
        ax.text(index, value + max(gas_values) * 0.025, f"{value / THOUSAND:.0f}k", ha="center", va="bottom", fontsize=6.8, color=INK)

    save(fig, "e2e_overhead")


def plot_stake_concentration():
    rows = read_csv("stake_concentration.csv")
    xs = [float(row["dominantStakeShare"]) for row in rows]
    dominant = [float(row["dominantPayout"]) for row in rows]
    others = [float(row["nonDominantAveragePayout"]) for row in rows]

    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    ax.plot(xs, dominant, color=COLORS["blue"], marker="o", label=r"Voter 2: $P_2$")
    ax.plot(xs, others, color=COLORS["orange"], marker="s", label=r"Mean others: $\frac{1}{7}\sum_{j\ne2}P_j$")

    set_common_axes(ax)
    ax.set_yscale("log")
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=5))
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.xaxis.set_major_formatter(FuncFormatter(percent))
    ax.set_xlabel(r"Dominant stake share $w_2 / \sum_j w_j$", labelpad=4)
    ax.set_ylabel(r"Fixed-budget payout $P_i$ ($\times 10^6$, log)", labelpad=4)
    ax.set_xlim(min(xs) - 0.03, max(xs) + 0.03)
    ax.yaxis.set_major_formatter(FuncFormatter(millions))
    ax.legend(loc="lower left", bbox_to_anchor=(0.0, 1.01), handlelength=1.7, borderaxespad=0.0)
    save(fig, "stake_concentration")


def plot_operating_cost_projection():
    rows = read_csv_if_exists("operating_cost_projection.csv")
    if not rows:
        return

    voter_counts = sorted({int(row["voters"]) for row in rows})
    networks = ["Ethereum L1", "Arbitrum execution"]
    colors = [COLORS["red"], COLORS["blue"]]
    width = 0.34
    xs = list(range(len(voter_counts)))

    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    for offset, network in enumerate(networks):
        values = [
            float(next(row for row in rows if row["network"] == network and int(row["voters"]) == voters)["totalUsd"])
            for voters in voter_counts
        ]
        positions = [x + (offset - 0.5) * width for x in xs]
        label = "L1, 20 gwei" if network == "Ethereum L1" else "Arbitrum, 0.1 gwei"
        ax.bar(positions, values, width=width, color=colors[offset], label=label)

    set_common_axes(ax)
    ax.set_xticks(xs, [str(voters) for voters in voter_counts])
    ax.set_xlabel("Voters claiming rewards", labelpad=4)
    ax.set_ylabel("Operating cost (USD, log)", labelpad=4)
    ax.set_yscale("log")
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=5))
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _pos: f"${x:g}"))
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.text(
        0.02,
        0.95,
        "deployment excluded; ETH=$3k",
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=6.6,
        color=MUTED,
    )
    ax.legend(loc="lower left", bbox_to_anchor=(0.0, 1.01), ncol=2, borderaxespad=0.0, handlelength=1.2)
    save(fig, "operating_cost_projection")


def plot_reward_scaling():
    rows = read_csv_if_exists("reward_scaling.csv")
    if not rows:
        return

    active_voters = [int(row["activeVoters"]) for row in rows]
    max_voters = int(rows[0]["maxVoters"])
    prove_seconds = [float(row["proveMs"]) / 1000.0 for row in rows]
    witness_seconds = [float(row["witnessMs"]) / 1000.0 for row in rows]
    prove_per_voter = [float(row["proveMsPerActiveVoter"]) / 1000.0 for row in rows]
    witness_per_voter = [
        (float(row["witnessMs"]) / int(row["activeVoters"])) / 1000.0 for row in rows
    ]

    fig, axes = plt.subplots(1, 2, figsize=(5.15, 2.35), constrained_layout=True)
    ax = axes[0]
    ax.plot(active_voters, prove_seconds, color=COLORS["green"], marker="o", label="prove")
    ax.plot(active_voters, witness_seconds, color=COLORS["purple"], marker="s", label="witness")
    set_common_axes(ax)
    ax.set_xlabel("Active voters", labelpad=4)
    ax.set_ylabel("Time (s)", labelpad=4)
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")
    ax.set_xticks(active_voters, [str(voter) for voter in active_voters])
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.legend(loc="lower left", bbox_to_anchor=(0.0, 1.01), ncol=2, borderaxespad=0.0, handlelength=1.4)

    ax = axes[1]
    ax.plot(active_voters, prove_per_voter, color=COLORS["blue"], marker="o", label="prove / voter")
    ax.plot(active_voters, witness_per_voter, color=COLORS["gray"], marker="D", label="witness / voter")
    set_common_axes(ax)
    ax.set_xlabel("Active voters", labelpad=4)
    ax.set_ylabel("Per-active time (s, log)", labelpad=4)
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")
    ax.set_xticks(active_voters, [str(voter) for voter in active_voters])
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.legend(loc="lower left", bbox_to_anchor=(0.0, 1.01), ncol=2, borderaxespad=0.0, handlelength=1.4)

    save(fig, "reward_scaling")


def plot_cost_profile():
    rows = read_csv("gas_breakdown.csv")
    label_map = {
        "commit": "Commit\nseed",
        "register": "Register\nroot",
        "reveal": "Reveal\nseed",
        "fund": "Fund\npool",
        "finalize": "Verify +\nfinalize",
        "claim": "Claim",
    }
    labels = [label_map[row["operation"]] for row in rows]
    values = [float(row["gas"]) for row in rows]
    color_map = {
        "commit": COLORS["purple"],
        "register": COLORS["blue"],
        "reveal": COLORS["purple"],
        "fund": COLORS["gray"],
        "finalize": COLORS["green"],
        "claim": COLORS["orange"],
    }
    colors = [color_map[row["operation"]] for row in rows]

    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    bars = ax.bar(range(len(labels)), values, color=colors, width=0.62)
    set_common_axes(ax)
    ax.set_xticks(range(len(labels)), labels)
    ax.set_ylabel(r"Gas ($\times 10^3$)", labelpad=4)
    ax.yaxis.set_major_formatter(FuncFormatter(thousands))
    ax.set_ylim(0, max(values) * 1.22)

    for bar, value in zip(bars, values):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            value + max(values) * 0.025,
            f"{value / THOUSAND:.0f}k",
            ha="center",
            va="bottom",
            fontsize=7.2,
            color=INK,
        )
    save(fig, "cost_profile")


def plot_attack_simulation():
    rows = read_csv_if_exists("attack_simulation.csv")
    if not rows:
        return

    gammas = ["0.02", "0.05", "0.10"]
    colors = [COLORS["blue"], COLORS["green"], COLORS["purple"]]
    fig, ax = plt.subplots(figsize=(3.55, 2.45), constrained_layout=True)
    for gamma, color in zip(gammas, colors):
        points = [
            (
                int(row["rounds"]),
                float(row["empiricalAdvantage"]),
                float(row["theoryAdvantage"]),
            )
            for row in rows
            if row["gamma"] == gamma
        ]
        points.sort()
        xs = [point[0] for point in points]
        empirical = [point[1] for point in points]
        theory = [point[2] for point in points]
        ax.plot(xs, empirical, color=color, label=rf"$\gamma={gamma}$ empirical")
        ax.plot(xs, theory, color=color, linestyle="--", alpha=0.75)

    set_common_axes(ax)
    ax.set_xlabel("Repeated rounds $k$", labelpad=4)
    ax.set_ylabel("Classifier advantage", labelpad=4)
    ax.yaxis.set_major_formatter(FuncFormatter(percent))
    ax.set_xlim(1, 50)
    ax.set_ylim(0, 0.52)
    ax.text(
        0.04,
        0.08,
        "dashed: theory curve",
        transform=ax.transAxes,
        ha="left",
        va="bottom",
        fontsize=6.8,
        color=MUTED,
    )
    ax.legend(loc="lower right", handlelength=1.8)
    save(fig, "attack_simulation")


def main():
    if not DATA_DIR.exists():
        raise SystemExit("missing experiment data; run npm run experiments:reward-data first")
    configure_style()
    plot_reward_sensitivity()
    plot_lottery_confidence()
    plot_budget_allocation()
    plot_e2e_overhead()
    plot_stake_concentration()
    plot_operating_cost_projection()
    plot_reward_scaling()
    plot_cost_profile()
    plot_attack_simulation()


if __name__ == "__main__":
    main()
