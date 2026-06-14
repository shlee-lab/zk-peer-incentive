#!/usr/bin/env python3

import csv
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    from matplotlib.ticker import FuncFormatter
except ModuleNotFoundError as err:
    raise SystemExit(
        "Missing matplotlib. From poc/, run:\n"
        "  python3 -m venv .venv\n"
        "  . .venv/bin/activate\n"
        "  pip install -r requirements.txt"
    ) from err


REPO_ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = REPO_ROOT / "results"
FIG_DIR = RESULTS_DIR / "figures"
CSV_FILE = RESULTS_DIR / "scaling_reward_layer.csv"

INK = "#1f2937"
GRID = "#e5e7eb"
BLUE = "#1f77b4"
ORANGE = "#ff7f0e"
GREEN = "#2ca02c"
PURPLE = "#9467bd"


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
            "legend.fontsize": 7.2,
            "legend.frameon": False,
            "lines.linewidth": 1.8,
            "lines.markersize": 4.2,
            "grid.color": GRID,
            "grid.linewidth": 0.55,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "savefig.bbox": "tight",
            "savefig.pad_inches": 0.08,
        }
    )


def read_rows():
    if not CSV_FILE.exists():
        raise SystemExit(f"Missing {CSV_FILE}; run npm run benchmark:reward-layer-scaling first.")
    with CSV_FILE.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    rows.sort(key=lambda row: int(row["N"]))
    return rows


def values(rows, key, scale=1.0):
    return [float(row[key]) / scale for row in rows]


def ns(rows):
    return [int(row["N"]) for row in rows]


def compact(x, _pos=None):
    if x >= 1_000_000:
        return f"{x / 1_000_000:.1f}M"
    if x >= 1_000:
        return f"{x / 1_000:.0f}k"
    return f"{x:.0f}"


def seconds(x, _pos=None):
    return f"{x:.0f}s"


def set_common_axes(ax):
    ax.grid(True, axis="y")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.set_axisbelow(True)


def save(fig, stem):
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    pdf = FIG_DIR / f"{stem}.pdf"
    png = FIG_DIR / f"{stem}.png"
    fig.savefig(pdf)
    fig.savefig(png, dpi=300)
    plt.close(fig)
    print(f"Wrote {pdf}")
    print(f"Wrote {png}")


def single_plot(rows, key, ylabel, stem, color, scale=1.0, formatter=None):
    fig, ax = plt.subplots(figsize=(3.45, 2.35), constrained_layout=True)
    ax.plot(ns(rows), values(rows, key, scale), marker="o", color=color)
    ax.set_xlabel("Reporters N")
    ax.set_ylabel(ylabel)
    ax.set_xscale("log", base=2)
    ax.set_xticks(ns(rows), [str(n) for n in ns(rows)])
    if formatter:
        ax.yaxis.set_major_formatter(FuncFormatter(formatter))
    set_common_axes(ax)
    save(fig, stem)


def summary_plot(rows):
    fig, axes = plt.subplots(1, 3, figsize=(7.2, 2.35), constrained_layout=True)
    x = ns(rows)

    axes[0].plot(x, values(rows, "rewardCircuitConstraints"), marker="o", color=BLUE)
    axes[0].set_title("A. Circuit size")
    axes[0].set_ylabel("Constraints")
    axes[0].yaxis.set_major_formatter(FuncFormatter(compact))

    axes[1].plot(x, values(rows, "proofGenerationTimeMs", 1000.0), marker="o", color=ORANGE)
    axes[1].set_title("B. Proving time")
    axes[1].set_ylabel("Proof time")
    axes[1].yaxis.set_major_formatter(FuncFormatter(seconds))

    axes[2].plot(x, values(rows, "totalRewardLayerGasExcludingIndividualClaims"), marker="o", color=GREEN)
    axes[2].set_title("C. Reward-layer gas")
    axes[2].set_ylabel("Gas, claims excluded")
    axes[2].yaxis.set_major_formatter(FuncFormatter(compact))

    for ax in axes:
        ax.set_xlabel("Reporters N")
        ax.set_xscale("log", base=2)
        ax.set_xticks(x, [str(n) for n in x])
        set_common_axes(ax)

    save(fig, "reward_layer_scaling_summary")


def main():
    configure_style()
    rows = read_rows()
    summary_plot(rows)
    single_plot(rows, "rewardCircuitConstraints", "Constraints", "constraints_vs_n", BLUE, formatter=compact)
    single_plot(rows, "proofGenerationTimeMs", "Proof generation time (s)", "proving_time_vs_n", ORANGE, scale=1000.0, formatter=seconds)
    single_plot(rows, "totalRewardLayerGasExcludingIndividualClaims", "Reward-layer gas", "reward_layer_gas_vs_n", GREEN, formatter=compact)
    single_plot(rows, "totalClaimGasIfAllNRecipientsClaim", "Total claim gas if all claim", "total_claim_gas_vs_n", PURPLE, formatter=compact)
    single_plot(rows, "rewardTranscriptSizeBytes", "Finalize calldata bytes", "transcript_size_vs_n", "#d62728", formatter=compact)


if __name__ == "__main__":
    main()
