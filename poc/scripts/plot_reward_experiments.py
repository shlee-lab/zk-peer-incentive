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
        ("consensus", "equal-split cases", COLORS["gray"], "^"),
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
    ax.set_xticks([0, 25, 50, 100, 150])
    ax.set_xlim(-3, 155)
    ax.set_ylim(0.10, 0.53)
    ax.legend(
        ncol=2,
        loc="lower left",
        bbox_to_anchor=(0.0, 1.01),
        handlelength=1.7,
        columnspacing=1.0,
        borderaxespad=0.0,
    )
    save(fig, "reward_sensitivity")


def plot_budget_allocation():
    rows = read_csv("budget_allocation.csv")
    labels = [str(int(row["voterIndex"])) for row in rows]
    payouts = [float(row["payout"]) for row in rows]
    peer_matches = [int(row["peerMatch"]) for row in rows]
    colors = [COLORS["blue"] if match == 1 else COLORS["gray"] for match in peer_matches]
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
            Patch(facecolor=COLORS["blue"], label="peer match"),
            Patch(facecolor=COLORS["gray"], label="baseline only"),
        ],
        loc="lower left",
        bbox_to_anchor=(0.0, 1.01),
        ncol=2,
        handlelength=1.2,
        columnspacing=1.0,
        borderaxespad=0.0,
    )
    save(fig, "budget_allocation")


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


def plot_cost_profile():
    rows = read_csv("gas_breakdown.csv")
    label_map = {
        "register": "Register\nroot",
        "fund": "Fund\npool",
        "finalize": "Verify +\nfinalize",
        "claim": "Claim",
    }
    labels = [label_map[row["operation"]] for row in rows]
    values = [float(row["gas"]) for row in rows]
    colors = [COLORS["blue"], COLORS["gray"], COLORS["green"], COLORS["purple"]]

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


def main():
    if not DATA_DIR.exists():
        raise SystemExit("missing experiment data; run npm run experiments:reward-data first")
    configure_style()
    plot_reward_sensitivity()
    plot_budget_allocation()
    plot_stake_concentration()
    plot_cost_profile()


if __name__ == "__main__":
    main()
