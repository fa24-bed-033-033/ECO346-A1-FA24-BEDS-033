#!/usr/bin/env python3
"""04_relationship_py.py

Question 5 — reproduce the Question 3 band table and figure in Python.
The band table must agree with R's to the rupee.

Reads the same two CSVs from data/ and writes figures/relationship_py.svg.
Prints the band table and the 25-29 band mean so it can be compared with R.
"""

from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

ROOT     = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
FIG_DIR  = ROOT / "figures"
FIG_DIR.mkdir(exist_ok=True)

# -----------------------------------------------------------------------------
# 1. Load and prepare the sample (same rules as the R scripts).
# -----------------------------------------------------------------------------
person = pd.read_csv(DATA_DIR / "pslm_person_subset.csv")
hh     = pd.read_csv(DATA_DIR / "pslm_hh_subset.csv")

dat = person.merge(
    hh[["hhid", "hhweight", "prov_code", "urban_rural"]],
    on="hhid", how="left"
)

earners = dat[
    (dat["prov_code"] == 2) & (dat["urban_rural"] == 2) &
    (dat["age"].between(15, 64)) &
    (dat["earn_annual"].notna()) & (dat["earn_annual"] > 0)
].copy()

# -----------------------------------------------------------------------------
# 2. Age bands 15-19, 20-24, ..., 60-64 and their midpoints.
# -----------------------------------------------------------------------------
earners["band_lo"]  = 15 + 5 * ((earners["age"] - 15) // 5)
earners["band_mid"] = earners["band_lo"] + 2
earners["band_lbl"] = earners["band_lo"].astype(int).astype(str) + "-" + \
                      (earners["band_lo"].astype(int) + 4).astype(str)

# -----------------------------------------------------------------------------
# 3. Weighted band means, rounded to whole rupees (matches R to the rupee).
# -----------------------------------------------------------------------------
def wmean(g):
    return np.sum(g["hhweight"] * g["earn_annual"]) / np.sum(g["hhweight"])

bands = (
    earners.groupby(["band_lo", "band_mid", "band_lbl"], as_index=False)
    .apply(lambda g: pd.Series({"n": len(g), "mean_w": wmean(g)}))
    .reset_index(drop=True)
    .sort_values("band_lo")
)
bands["thin"] = bands["n"] < 30
bands["mean_w"] = bands["mean_w"].round().astype(int)

# -----------------------------------------------------------------------------
# 4. The figure. Same choices as the R version: log y, jitter at most 0.4
#    years, semi-transparent small points, red band means with hollow markers
#    for thin bands, direct annotation of the peak.
# -----------------------------------------------------------------------------
rng = np.random.default_rng(1)                # reproducible jitter
age_jit = earners["age"].to_numpy() + rng.uniform(-0.4, 0.4, size=len(earners))

fig, ax = plt.subplots(figsize=(8, 5.5))
ax.scatter(age_jit, earners["earn_annual"], s=5, alpha=0.15, color="#4C78A8")

solid = bands[~bands["thin"]]
hollow = bands[bands["thin"]]
ax.plot(bands["band_mid"], bands["mean_w"], color="#D1495B", linewidth=1.6, zorder=3)
ax.scatter(solid["band_mid"], solid["mean_w"],
           s=70, color="#D1495B", edgecolor="#D1495B", zorder=4)
ax.scatter(hollow["band_mid"], hollow["mean_w"],
           s=70, facecolor="white", edgecolor="#D1495B", linewidth=1.6, zorder=4)

top = bands.loc[bands["mean_w"].idxmax()]
ax.annotate(
    f"Peak: band {top['band_lbl']}\nRs {top['mean_w']:,}",
    xy=(top["band_mid"], top["mean_w"]),
    xytext=(top["band_mid"], top["mean_w"] * 1.35),
    ha="center", color="#D1495B", fontsize=9, fontweight="bold",
)

ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.set_xlim(15, 64)
ax.set_xticks(range(15, 66, 5))
ax.yaxis.set_major_locator(mticker.FixedLocator([1e4, 1e5, 1e6, 1e7]))
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f"Rs {int(v):,}"))

ax.set_xlabel("Age")
ax.set_ylabel("Annual earnings (log scale)")
ax.set_title(
    f"Earnings in Punjab's urban workforce rise with experience and peak in the {top['band_lbl']} band",
    fontsize=10, fontweight="bold", loc="left"
)
fig.text(
    0.02, -0.02,
    "Source: PSLM 2019-20, person file linked to household file by hhid.\n"
    "Sample: Punjab urban persons aged 15-64 with earn_annual > 0.\n"
    "Band means weighted by hhweight. Hollow markers = fewer than 30 unweighted observations.",
    fontsize=7, color="#555555", ha="left", va="top",
)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
ax.grid(True, which="major", axis="y", color="#eeeeee")

fig.tight_layout()
fig.savefig(FIG_DIR / "relationship_py.svg", bbox_inches="tight")

# -----------------------------------------------------------------------------
# 5. Print the band table and the 25-29 cross-check.
# -----------------------------------------------------------------------------
print("\n----- Question 5 band table (Python) -----")
print(bands[["band_lbl", "n", "mean_w"]].to_string(index=False))
print(f"\n25-29 band weighted mean (Python): Rs {int(bands.loc[bands['band_lbl']=='25-29','mean_w'].iloc[0]):,}")
print("Compare with the R value printed by 03_relationship.R; they must match to the rupee.")
