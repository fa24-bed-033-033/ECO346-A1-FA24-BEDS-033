# 03_relationship.R
# Question 3 — annual earnings (log scale) against age for variant 1 earners.
# Every earner is a jittered, semi-transparent point. Weighted band means at
# the midpoints 17, 22, ..., 62 are drawn as larger markers joined by a line;
# thin bands (fewer than 30 unweighted observations) get HOLLOW markers.
# The band with the highest weighted mean is annotated directly.
#
# Also the figure the Q4 default is REDESIGNED into.

suppressPackageStartupMessages({
  library(ggplot2)
  library(svglite)
})

# -----------------------------------------------------------------------------
# 1. Load and prepare the sample.
# -----------------------------------------------------------------------------
person <- read.csv("data/pslm_person_subset.csv", stringsAsFactors = FALSE)
hh     <- read.csv("data/pslm_hh_subset.csv",     stringsAsFactors = FALSE)

dat <- merge(
  person,
  hh[, c("hhid", "hhweight", "prov_code", "urban_rural")],
  by = "hhid", all.x = TRUE
)

earners <- subset(
  dat,
  prov_code == 2 & urban_rural == 2 &
    age >= 15 & age <= 64 &
    !is.na(earn_annual) & earn_annual > 0
)

# -----------------------------------------------------------------------------
# 2. Age bands 15-19, 20-24, ..., 60-64 with midpoints 17, 22, ..., 62.
# -----------------------------------------------------------------------------
band_lower <- function(a) 15 + 5 * floor((a - 15) / 5)
earners$band_lo  <- band_lower(earners$age)
earners$band_mid <- earners$band_lo + 2
earners$band_lbl <- sprintf("%d-%d", earners$band_lo, earners$band_lo + 4)

# -----------------------------------------------------------------------------
# 3. Band table: n (unweighted) and weighted mean earnings.
#    "Thin" means fewer than 30 unweighted observations.
# -----------------------------------------------------------------------------
bands <- aggregate(
  cbind(n = earn_annual, mean_w = earn_annual) ~ band_lo + band_mid + band_lbl,
  data = earners, FUN = length
)
bands$n <- bands$mean_w  # length() filled both; recompute mean below.
bands$mean_w <- sapply(bands$band_lo, function(lo) {
  rows <- earners[earners$band_lo == lo, ]
  sum(rows$hhweight * rows$earn_annual) / sum(rows$hhweight)
})
bands$thin <- bands$n < 30
bands <- bands[order(bands$band_lo), ]

# Pretty version for the README.
band_table <- data.frame(
  Band    = bands$band_lbl,
  Earners = bands$n,
  WeightedMeanEarnings = round(bands$mean_w)
)

top_band <- bands[which.max(bands$mean_w), ]

# -----------------------------------------------------------------------------
# 4. The plot.
#    Semi-transparent points (alpha = 0.15 for ~Punjab-urban densities;
#    tuned so clusters stay readable without the single points vanishing).
#    Horizontal jitter is capped at 0.4 years as the brief requires.
# -----------------------------------------------------------------------------
power_breaks <- 10 ^ (4:7)
rs_fmt <- function(x) paste0("Rs ", format(round(x), big.mark = ",", scientific = FALSE))

p <- ggplot() +
  geom_jitter(
    data = earners,
    aes(x = age, y = earn_annual),
    width = 0.4, height = 0,
    alpha = 0.15, size = 0.6, colour = "#4C78A8"
  ) +
  geom_line(
    data = bands,
    aes(x = band_mid, y = mean_w),
    colour = "#D1495B", linewidth = 0.9
  ) +
  geom_point(
    data = bands,
    aes(x = band_mid, y = mean_w, shape = thin),
    colour = "#D1495B", fill = "white", size = 3.2, stroke = 1.1
  ) +
  scale_shape_manual(
    values = c(`FALSE` = 16, `TRUE` = 21),      # solid vs hollow
    guide  = "none"
  ) +
  scale_y_log10(
    breaks = power_breaks,
    labels = sapply(power_breaks, rs_fmt),
    limits = c(1e4, 1e7)
  ) +
  scale_x_continuous(breaks = seq(15, 65, 5), limits = c(15, 64)) +
  annotate(
    "text",
    x = top_band$band_mid, y = top_band$mean_w * 1.35,
    label = sprintf("Peak: band %s\n%s", top_band$band_lbl, rs_fmt(top_band$mean_w)),
    size = 3.3, fontface = "bold", colour = "#D1495B"
  ) +
  labs(
    title = sprintf(
      "Earnings in Punjab's urban workforce rise with experience and peak in the %s band",
      top_band$band_lbl
    ),
    x = "Age",
    y = "Annual earnings (log scale)",
    caption = paste(
      "Source: PSLM 2019-20, person file linked to household file by hhid.",
      "Sample: Punjab urban persons aged 15-64 with earn_annual > 0.",
      "Band means weighted by hhweight. Hollow markers = fewer than 30 unweighted observations.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_text(face = "bold", size = 11),
    plot.caption     = element_text(hjust = 0, size = 8, colour = "#555555"),
    panel.grid.minor = element_blank()
  )

ggsave("figures/relationship.svg", p, width = 8, height = 5.5)

# -----------------------------------------------------------------------------
# 5. Numbers for the README and the Google Form.
# -----------------------------------------------------------------------------
mean_25_29 <- bands$mean_w[bands$band_lbl == "25-29"]
mean_45_49 <- bands$mean_w[bands$band_lbl == "45-49"]

cat("\n----- Question 3 answers -----\n")
cat(sprintf("Weighted mean, 25-29: Rs %s\n", format(round(mean_25_29), big.mark = ",")))
cat(sprintf("Weighted mean, 45-49: Rs %s\n", format(round(mean_45_49), big.mark = ",")))
cat(sprintf("Highest weighted mean band: %s (Rs %s)\n",
            top_band$band_lbl, format(round(top_band$mean_w), big.mark = ",")))
cat("\nBand table:\n")
print(band_table, row.names = FALSE)

# Save the band table as CSV so the README can be regenerated from it.
write.csv(band_table, "figures/band_table.csv", row.names = FALSE)
