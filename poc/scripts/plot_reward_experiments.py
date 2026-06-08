#!/usr/bin/env python3

import csv
from pathlib import Path

try:
    import matplotlib.pyplot as plt
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
            "savefig.pad_inches": 0.035,
        }
    )


def read_csv(name):
    with open(DATA_DIR / name, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def save(fig, stem):
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    pdf = FIG_DIR / f"{stem}.pdf"
    png = FIG_DIR / f"{stem}.png"
    fig.savefig(pdf)
    fig.savefig(png, dpi=300)
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


def plot_reward_sensitivity():
    rows = read_csv("reward_sensitivity.csv")
    profiles = [
        ("maci_anvil_reports", "MACI-derived", COLORS["blue"], "o"),
        ("one_sided", "one-sided", COLORS["green"], "s"),
        ("consensus", "consensus", COLORS["purple"], "^"),
        ("alternating", "alternating", COLORS["red"], "D"),
    ]

    fig, ax = plt.subplots(figsize=(3.35, 2.25), constrained_layout=True)
    for profile, label, color, marker in profiles:
        points = [
            (float(row["kappa"]), float(row["totalScore"]))
            for row in rows
            if row["profile"] == profile and row["smoothing"] == "1"
        ]
        points.sort()
        xs = [x for x, _ in points]
        ys = [y for _, y in points]
        ax.plot(xs, ys, color=color, marker=marker, label=label)

    set_common_axes(ax)
    ax.set_xlabel(r"Incentive scale $\kappa$")
    ax.set_ylabel(r"Unnormalized score mass $\sum_i T_i$ ($\times 10^6$)")
    ax.yaxis.set_major_formatter(FuncFormatter(millions))
    ax.set_xticks([50, 100, 150])
    ax.set_xlim(45, 155)
    ax.set_ylim(bottom=-0.35 * MILLION)
    ax.legend(ncol=2, loc="upper left", handlelength=1.7, columnspacing=1.0)
    save(fig, "reward_sensitivity")


def plot_budget_allocation():
    rows = read_csv("budget_allocation.csv")
    labels = [str(int(row["voterIndex"])) for row in rows]
    payouts = [float(row["payout"]) for row in rows]
    reports = [int(row["report"]) for row in rows]
    colors = [COLORS["blue"] if report == 1 else COLORS["orange"] for report in reports]
    total = sum(payouts)
    fig, ax = plt.subplots(figsize=(3.35, 2.25), constrained_layout=True)
    bars = ax.bar(range(len(labels)), payouts, color=colors, width=0.62)
    set_common_axes(ax)
    ax.set_xlabel("Voter index")
    ax.set_ylabel(r"Fixed-budget payout $P_i$ ($\times 10^6$)")
    ax.yaxis.set_major_formatter(FuncFormatter(millions))
    ax.set_xticks(range(len(labels)), labels)
    ax.set_ylim(0, max(payouts) * 1.22)

    for bar, value in zip(bars, payouts):
        if value < 0.05 * MILLION:
            continue
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            value + max(payouts) * 0.025,
            f"{value / MILLION:.2f}",
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
    save(fig, "budget_allocation")


def plot_stake_concentration():
    rows = read_csv("stake_concentration.csv")
    xs = [float(row["dominantStakeShare"]) for row in rows]
    dominant = [float(row["dominantPayout"]) for row in rows]
    others = [float(row["nonDominantAveragePayout"]) for row in rows]

    fig, ax = plt.subplots(figsize=(3.35, 2.25), constrained_layout=True)
    ax.plot(xs, dominant, color=COLORS["blue"], marker="o", label=r"Voter 2: $P_2$")
    ax.plot(xs, others, color=COLORS["orange"], marker="s", label=r"Mean others: $\frac{1}{7}\sum_{j\ne2}P_j$")

    set_common_axes(ax)
    ax.set_yscale("log")
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=5))
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.xaxis.set_major_formatter(FuncFormatter(percent))
    ax.set_xlabel(r"Dominant stake share $w_2 / \sum_j w_j$")
    ax.set_ylabel(r"Fixed-budget payout $P_i$ ($\times 10^6$, log)")
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

    fig, ax = plt.subplots(figsize=(3.35, 2.25), constrained_layout=True)
    bars = ax.bar(range(len(labels)), values, color=colors, width=0.62)
    set_common_axes(ax)
    ax.set_xticks(range(len(labels)), labels)
    ax.set_ylabel(r"Gas ($\times 10^3$)")
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
