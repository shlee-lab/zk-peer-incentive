#!/usr/bin/env python3

import csv
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "experiments" / "reward-evaluation"
DATA_DIR = OUT_DIR / "data"
FIG_DIR = OUT_DIR / "figures"

COLORS = ["#1f77b4", "#d62728", "#2ca02c", "#9467bd", "#ff7f0e", "#17becf"]
TEXT = "#202124"
GRID = "#d9dee7"
AXIS = "#5f6368"
BG = "#ffffff"


def font(size, bold=False):
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
    ]
    for candidate in candidates:
        if os.path.exists(candidate):
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


FONT_TITLE = font(34, True)
FONT_SUBTITLE = font(20)
FONT_LABEL = font(18)
FONT_SMALL = font(15)
FONT_TINY = font(13)


def read_csv(name):
    with open(DATA_DIR / name, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def save_figure(image, stem):
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    png = FIG_DIR / f"{stem}.png"
    pdf = FIG_DIR / f"{stem}.pdf"
    image.save(png)
    image.convert("RGB").save(pdf, "PDF", resolution=160)
    print(f"Wrote {png}")
    print(f"Wrote {pdf}")


def text_center(draw, xy, text, fill, font_obj):
    bbox = draw.textbbox((0, 0), text, font=font_obj)
    x, y = xy
    draw.text((x - (bbox[2] - bbox[0]) / 2, y - (bbox[3] - bbox[1]) / 2), text, fill=fill, font=font_obj)


def nice_ticks(ymin, ymax, count=5):
    if ymax <= ymin:
        ymax = ymin + 1
    step = (ymax - ymin) / count
    return [ymin + step * i for i in range(count + 1)]


def draw_axes(draw, area, xmin, xmax, ymin, ymax, xlabel, ylabel, draw_x_ticks=True):
    left, top, right, bottom = area
    draw.rectangle(area, outline="#e9edf3", width=1)
    for value in nice_ticks(ymin, ymax):
        y = bottom - (value - ymin) / (ymax - ymin) * (bottom - top)
        draw.line((left, y, right, y), fill=GRID, width=1)
        draw.text((left - 76, y - 10), f"{value:,.1f}", fill=AXIS, font=FONT_TINY)
    draw.line((left, bottom, right, bottom), fill=AXIS, width=2)
    draw.line((left, top, left, bottom), fill=AXIS, width=2)
    if draw_x_ticks:
        for value in nice_ticks(xmin, xmax, 4):
            x = left + (value - xmin) / (xmax - xmin) * (right - left)
            draw.line((x, bottom, x, bottom + 6), fill=AXIS, width=1)
            label = f"{value:.0f}" if abs(value) >= 10 else f"{value:.2f}"
            text_center(draw, (x, bottom + 22), label, AXIS, FONT_TINY)
    text_center(draw, ((left + right) / 2, bottom + 52), xlabel, AXIS, FONT_LABEL)
    draw.text((left - 86, top - 34), ylabel, fill=AXIS, font=FONT_LABEL)


def line_chart(title, subtitle, series, xlabel, ylabel, y_scale=1.0, y_suffix="", stem="chart"):
    width, height = 1200, 720
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    draw.text((56, 34), title, fill=TEXT, font=FONT_TITLE)
    draw.text((58, 78), subtitle, fill=AXIS, font=FONT_SUBTITLE)

    area = (132, 150, 1070, 590)
    xs = [x for item in series for x, _ in item["points"]]
    ys = [y / y_scale for item in series for _, y in item["points"]]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = 0, max(ys) * 1.12 if ys else 1
    if xmax == xmin:
        xmax = xmin + 1
    draw_axes(draw, area, xmin, xmax, ymin, ymax, xlabel, ylabel)
    left, top, right, bottom = area

    for idx, item in enumerate(series):
        color = COLORS[idx % len(COLORS)]
        points = []
        for x, y_value in item["points"]:
            x_px = left + (x - xmin) / (xmax - xmin) * (right - left)
            y_px = bottom - ((y_value / y_scale) - ymin) / (ymax - ymin) * (bottom - top)
            points.append((x_px, y_px))
        if len(points) > 1:
            draw.line(points, fill=color, width=4, joint="curve")
        for point in points:
            draw.ellipse((point[0] - 5, point[1] - 5, point[0] + 5, point[1] + 5), fill=color)
        legend_x = 820
        legend_y = 116 + idx * 28
        draw.rectangle((legend_x, legend_y, legend_x + 22, legend_y + 12), fill=color)
        draw.text((legend_x + 32, legend_y - 4), item["label"], fill=TEXT, font=FONT_SMALL)

    if y_suffix:
        draw.text((956, 604), y_suffix, fill=AXIS, font=FONT_TINY)
    save_figure(image, stem)


def bar_chart(title, subtitle, bars, xlabel, ylabel, y_scale=1.0, stem="bars"):
    width, height = 1200, 720
    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)
    draw.text((56, 34), title, fill=TEXT, font=FONT_TITLE)
    draw.text((58, 78), subtitle, fill=AXIS, font=FONT_SUBTITLE)

    area = (132, 150, 1070, 590)
    values = [value / y_scale for _, value in bars]
    ymax = max(values) * 1.18 if values else 1
    draw_axes(draw, area, 0, max(len(bars) - 1, 1), 0, ymax, xlabel, ylabel, draw_x_ticks=False)
    left, top, right, bottom = area
    slot = (right - left) / max(len(bars), 1)
    bar_width = slot * 0.58
    for idx, (label, value) in enumerate(bars):
        scaled = value / y_scale
        x0 = left + idx * slot + (slot - bar_width) / 2
        x1 = x0 + bar_width
        y0 = bottom - scaled / ymax * (bottom - top)
        color = COLORS[idx % len(COLORS)]
        draw.rectangle((x0, y0, x1, bottom), fill=color)
        text_center(draw, ((x0 + x1) / 2, y0 - 18), f"{scaled:,.0f}", TEXT, FONT_TINY)
        text_center(draw, ((x0 + x1) / 2, bottom + 24), label, AXIS, FONT_TINY)
    save_figure(image, stem)


def plot_reward_sensitivity():
    rows = read_csv("reward_sensitivity.csv")
    series = []
    labels = {
        "maci_anvil_reports": "MACI-derived profile",
        "alternating": "alternating reports",
        "one_sided": "one-sided minority",
        "consensus": "consensus",
    }
    for profile in ["maci_anvil_reports", "alternating", "one_sided", "consensus"]:
        points = []
        for row in rows:
            if row["profile"] == profile and row["smoothing"] == "1":
                points.append((float(row["kappa"]), float(row["totalExpectedReward"])))
        points.sort()
        series.append({"label": labels[profile], "points": points})
    line_chart(
        "Reward sensitivity",
        "Total expected reward changes with incentive scale and report profile.",
        series,
        "kappa",
        "total expected reward / 1e6",
        y_scale=1_000_000.0,
        stem="reward_sensitivity",
    )


def plot_lottery_unbiasedness():
    rows = read_csv("lottery_trials.csv")
    points = [(float(row["trial"]), float(row["cumulativeMeanPayout"])) for row in rows]
    expected = float(rows[0]["theoreticalExpectedPayout"])
    series = [
        {"label": "empirical cumulative mean", "points": points},
        {"label": "theoretical expected payout", "points": [(1.0, expected), (float(rows[-1]["trial"]), expected)]},
    ]
    line_chart(
        "Lottery payout convergence",
        "Repeated public randomness samples converge toward the expected peer-prediction reward.",
        series,
        "sampled randomness trials",
        "mean total payout / 1e6",
        y_scale=1_000_000.0,
        stem="lottery_unbiasedness",
    )


def plot_stake_concentration():
    rows = read_csv("stake_concentration.csv")
    dominant = [(float(row["dominantStakeShare"]), float(row["dominantExpectedReward"])) for row in rows]
    average_points = [
        (float(row["dominantStakeShare"]), float(row["nonDominantAverageExpectedReward"])) for row in rows
    ]
    series = [
        {"label": "dominant voter expected reward", "points": dominant},
        {"label": "average other voter expected reward", "points": average_points},
    ]
    line_chart(
        "Stake concentration sensitivity",
        "Increasing one voter's stake raises their expected reward share under public-stake weighting.",
        series,
        "dominant voter stake share",
        "expected reward / 1e6",
        y_scale=1_000_000.0,
        stem="stake_concentration",
    )


def plot_cost_profile():
    gas_file = DATA_DIR / "gas_breakdown.csv"
    if gas_file.exists():
        rows = read_csv("gas_breakdown.csv")
        bars = [(row["operation"], float(row["gas"])) for row in rows if row.get("operation")]
        bar_chart(
            "Reward on-chain cost",
            "Gas measured on the local Anvil reward flow after proof generation.",
            bars,
            "operation",
            "gas / 1k",
            y_scale=1_000.0,
            stem="cost_profile",
        )
        return

    rows = read_csv("proof_shape.csv")
    selected = [row for row in rows if row["metric"] in {"constraints", "public_inputs", "private_inputs"}]
    bars = [(row["metric"].replace("_", " "), float(row["value"])) for row in selected]
    bar_chart(
        "Reward proof shape",
        "Circuit size summary for the fixed N=8 reward proof.",
        bars,
        "metric",
        "count",
        y_scale=1.0,
        stem="cost_profile",
    )


def main():
    if not DATA_DIR.exists():
        raise SystemExit("missing experiment data; run npm run experiments:reward-data first")
    plot_reward_sensitivity()
    plot_lottery_unbiasedness()
    plot_stake_concentration()
    plot_cost_profile()


if __name__ == "__main__":
    main()
