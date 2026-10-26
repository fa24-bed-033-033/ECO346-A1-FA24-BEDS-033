# ECO346 Assignment 1 — Fall 2026

**Registration number:** FA24-BEDS-033
**Section:** A
**Variant:** **1 — Punjab urban** (33 mod 8 = 1)

## How to reproduce

A fresh clone reproduces every figure and number with no manual step and no
internet connection. From the repository root:

```bash
Rscript scripts/01_default.R          # figures/default.svg
Rscript scripts/02_distribution.R     # figures/distribution.svg + Q2 numbers
Rscript scripts/03_relationship.R     # figures/relationship.svg + Q3 numbers + band_table.csv
python  scripts/04_relationship_py.py # figures/relationship_py.svg + Q5 numbers
```

Required R packages: `ggplot2`, `svglite`, `scales`. Required Python packages:
`pandas`, `numpy`, `matplotlib`.

---

## Question 2 — The distribution

![Distribution](figures/distribution.svg)

| Quantity | Value |
|---|---|
| Number of earners (variant 1) | **3,768** |
| Weighted median | **Rs 240,000** |
| Unweighted median | **Rs 240,000** |
| Weighted 10th percentile | **Rs 96,000** |
| Weighted 90th percentile | **Rs 660,000** |
| p90 / p10 | **6.88** |
| Excluded (outside Rs 10,000 – Rs 10,000,000) | **25** |

**Interpretation (≤80 words).** The histogram shows that annual earnings in
Punjab's urban workforce are heavily right-skewed even on a log scale: the mass
sits between roughly Rs 100,000 and Rs 500,000, with a long upper tail reaching
the millions. The weighted and unweighted medians are identical (Rs 240,000)
because earnings cluster at round contractual values (Rs 20,000 × 12 months),
and that cluster straddles the 50% mark whether or not households are
reweighted. The dispersion is wide: p90/p10 = 6.88.

---

## Question 3 — The relationship

![Relationship](figures/relationship.svg)

### Band table (weighted mean earnings by five-year age band)

| Band | Earners | Weighted mean earnings (Rs) |
|---|---:|---:|
| 15-19 | 229 | 145,444 |
| 20-24 | 449 | 216,585 |
| 25-29 | 499 | 320,776 |
| 30-34 | 518 | 369,580 |
| 35-39 | 498 | 354,031 |
| 40-44 | 435 | 498,966 |
| 45-49 | 427 | 465,073 |
| 50-54 | 363 | 521,949 |
| 55-59 | 220 | 523,751 |
| 60-64 | 130 | 453,067 |

Numbers are copied from `figures/band_table.csv`, written by
`03_relationship.R`.

- **Weighted mean, 25-29:** Rs **320,776**
- **Weighted mean, 45-49:** Rs **465,073**
- **Band with the highest weighted mean:** **55-59** (Rs 523,751)

**Interpretation (≤100 words).** Earnings in Punjab's urban workforce follow
the classical experience profile: they rise steeply from Rs 145,000 in the
15-19 band to around Rs 320,000 by the late 20s, grow more slowly through the
30s, and plateau in the 50s before easing in the 60s. The peak is in the 55-59
band at Rs 523,751, roughly 3.6 times the earnings of the youngest band. The
log scale makes the inside-band dispersion as visible as the between-band
change: two workers of the same age can differ by a factor of ten. **What it
cannot tell us:** this is a cross-section. The curve mixes age with cohort and
selection effects — older workers who are still earning may be systematically
different from those who left the workforce — so it is not evidence that an
individual's earnings will follow this path.

---

## Question 4 — The makeover

Default is `figures/default.svg` (committed before the redesign). The redesign
is the Question 3 figure, `figures/relationship.svg`.

**Explanation (≤150 words).** Three changes:

1. **Log scale on earnings.** The default's linear y-axis lets a handful of
   millionaire earners (up to Rs 24,000,000) stretch the axis so 95% of the
   data is pressed against zero. A log scale uses the vertical position
   channel — the one humans decode most accurately — across the whole range,
   so every age-earnings combination is legible. (Perceptual ranking of
   channels; log scale.)
2. **Semi-transparency and jitter.** The default overplots thousands of
   integer-aged points on top of each other, hiding the density: 3,768 dots
   collapse into vertical stripes. Alpha blending (0.15) and ±0.4-year
   horizontal jitter turn the point cloud into a readable density map.
   (Overplotting.)
3. **Weighted band means with a line.** The default shows no summary. Adding
   age-band weighted means at midpoints, joined by a line, puts the central
   tendency on the same figure as the raw points without extra ink.
   (Conditional means; data-ink.)

**What the default shows that the redesign hides:** the untransformed scale of
the top earners. On the log axis a Rs 24,000,000 outlier sits only a little
above the main cloud; on the default its sheer height makes the inequality
visible at a glance.

---

## Question 5 — A second language

Reproduced in **Python** with pandas + matplotlib: `scripts/04_relationship_py.py`.
Figure saved as `figures/relationship_py.svg`.

- **25-29 band weighted mean, R:** Rs **320,776**
- **25-29 band weighted mean, Python:** Rs **320,776**

The two agree to the rupee because both use the identical weighted-mean
formula (sum(w*x) / sum(w)) on the same CSVs, with age banded by the same
floor division.

**One differing default (≤80 words).** matplotlib's default scatter marker is
a larger filled dot than ggplot's, and its default y-axis is linear. To match
the R figure I set `s = 5` and `alpha = 0.15` on the point cloud and called
`ax.set_yscale("log")` with explicit `FixedLocator` ticks at 10^4, 10^5, 10^6,
10^7 formatted as `Rs ...`. matplotlib also does not jitter by default, so I
added `rng.uniform(-0.4, 0.4, size=n)` to `age` to match ggplot's
`geom_jitter` behaviour.

---

## Commits (minimum five, in order)

Suggested sequence (one piece of work per commit):

1. `Add data CSVs and data/README`
2. `Add default scatterplot (Q4 pre-redesign)`
3. `Add weighted histogram (Q2)`
4. `Add redesigned relationship figure and band table (Q3)`
5. `Add Python reproduction and band-table cross-check (Q5)`
6. `Add README interpretations and slides`

The default figure of Q4 is committed **before** its redesign.
