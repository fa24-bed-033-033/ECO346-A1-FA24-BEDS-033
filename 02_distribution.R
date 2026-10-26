# 02_distribution.R
# Question 2 — weighted histogram of annual earnings for variant 1 earners.
# Bins 0.1 wide in log10 units from 4.0 to 7.0 (Rs 10,000 to Rs 10,000,000).
# Vertical axis = density per log10 unit. Horizontal axis labeled in rupees.
# Dashed vertical lines at the weighted median and the weighted 90th percentile,
# each labeled directly with its value in rupees.
#
# Reports to the console: number of earners, weighted and unweighted medians,
# weighted 10th and 90th percentiles and their ratio, number excluded.

suppressPackageStartupMessages({
  library(ggplot2)
  library(svglite)
  library(scales)
})

# -----------------------------------------------------------------------------
# 1. Load and prepare the sample (same as 01_default.R).
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
  prov_code == 2 & urban_rural == 2 &          # variant 1: Punjab urban
    age >= 15 & age <= 64 &
    !is.na(earn_annual) & earn_annual > 0
)

n_total <- nrow(earners)

# -----------------------------------------------------------------------------
# 2. Weighted quantile exactly as the brief defines it.
#    Sort by x, cumulate shares of weight, take the smallest x whose
#    cumulative share reaches or exceeds p. R's built-in quantile() does NOT
#    do this and will not match the answer key.
# -----------------------------------------------------------------------------
w_quantile <- function(x, w, p) {
  o  <- order(x)
  xs <- x[o]
  ws <- w[o]
  cw <- cumsum(ws) / sum(ws)
  xs[which(cw >= p)[1]]
}

med_w   <- w_quantile(earners$earn_annual, earners$hhweight, 0.5)
med_unw <- median(earners$earn_annual)
p10_w   <- w_quantile(earners$earn_annual, earners$hhweight, 0.10)
p90_w   <- w_quantile(earners$earn_annual, earners$hhweight, 0.90)
ratio   <- p90_w / p10_w

# -----------------------------------------------------------------------------
# 3. Keep only earners inside the plotted window [10,000; 10,000,000] and
#    count how many were excluded.
# -----------------------------------------------------------------------------
in_range <- earners$earn_annual >= 1e4 & earners$earn_annual <= 1e7
n_excluded <- sum(!in_range)
d <- earners[in_range, ]
d$log_earn <- log10(d$earn_annual)

# -----------------------------------------------------------------------------
# 4. Weighted histogram. Density per log10 unit = (sum of weights in bin) /
#    (total weight * 0.1). The area under the histogram then sums to 1.
# -----------------------------------------------------------------------------
breaks  <- seq(4.0, 7.0, by = 0.1)
bin_mid <- head(breaks, -1) + 0.05
bin_idx <- findInterval(d$log_earn, breaks, rightmost.closed = TRUE)

w_total <- sum(d$hhweight)
w_in_bin <- tapply(d$hhweight, factor(bin_idx, levels = seq_along(bin_mid)), sum)
w_in_bin[is.na(w_in_bin)] <- 0
density <- as.numeric(w_in_bin) / (w_total * 0.1)

hist_df <- data.frame(bin_mid = bin_mid, density = density)

# -----------------------------------------------------------------------------
# 5. The plot.
# -----------------------------------------------------------------------------
power_breaks <- 10 ^ (4:7)          # 1e4, 1e5, 1e6, 1e7

rs_fmt <- function(x) paste0("Rs ", format(round(x), big.mark = ",", scientific = FALSE))

p <- ggplot(hist_df, aes(x = bin_mid, y = density)) +
  geom_col(width = 0.1, fill = "#4C78A8", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = log10(med_w),  linetype = "dashed", colour = "#333333") +
  geom_vline(xintercept = log10(p90_w),  linetype = "dashed", colour = "#333333") +
  annotate("text",
           x = log10(med_w), y = max(hist_df$density) * 0.95,
           label = paste0("Median\n", rs_fmt(med_w)),
           hjust = -0.1, vjust = 1, size = 3.3) +
  annotate("text",
           x = log10(p90_w), y = max(hist_df$density) * 0.95,
           label = paste0("90th pct\n", rs_fmt(p90_w)),
           hjust = -0.1, vjust = 1, size = 3.3) +
  scale_x_continuous(
    breaks = log10(power_breaks),
    labels = sapply(power_breaks, rs_fmt),
    limits = c(4.0, 7.0),
    expand = c(0, 0)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = sprintf(
      "Earnings in Punjab's urban workforce are heavily right-skewed: the top tenth earns %.1fx the bottom tenth",
      ratio
    ),
    x = "Annual earnings (log scale)",
    y = "Density per log10 unit",
    caption = sprintf(
      "Source: PSLM 2019-20, person file linked to household file by hhid.\nSample: Punjab urban persons aged 15-64 with earn_annual > 0. Weighted by hhweight.\n%d earners plotted; %d outside Rs 10,000-Rs 10,000,000 excluded.",
      nrow(d), n_excluded
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 11),
    plot.caption  = element_text(hjust = 0, size = 8, colour = "#555555"),
    panel.grid.minor = element_blank()
  )

ggsave("figures/distribution.svg", p, width = 8, height = 5)

# -----------------------------------------------------------------------------
# 6. Numbers to copy into README.md and the Google Form.
# -----------------------------------------------------------------------------
cat("\n----- Question 2 answers -----\n")
cat(sprintf("Number of earners (variant 1, full sample): %d\n", n_total))
cat(sprintf("Weighted median:   Rs %s\n", format(round(med_w),   big.mark = ",")))
cat(sprintf("Unweighted median: Rs %s\n", format(round(med_unw), big.mark = ",")))
cat(sprintf("Weighted 10th pct: Rs %s\n", format(round(p10_w),   big.mark = ",")))
cat(sprintf("Weighted 90th pct: Rs %s\n", format(round(p90_w),   big.mark = ",")))
cat(sprintf("p90 / p10 ratio:   %.2f\n", ratio))
cat(sprintf("Excluded (outside Rs 10,000 - Rs 10,000,000): %d\n", n_excluded))
cat(sprintf("Earners plotted:   %d\n\n", nrow(d)))
