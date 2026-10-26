# 01_default.R
# Question 4 — the "default" figure before the redesign.
# ggplot2 with nothing added: geom_point() on (age, earn_annual) for variant 1
# (Punjab urban) earners aged 15-64 with earn_annual > 0.
#
# Save as figures/default.svg. This file must be committed BEFORE the redesign.

# -----------------------------------------------------------------------------
# 0. Packages. install.packages() calls are commented so the script can run
#    offline from a fresh clone; uncomment the first time only.
# -----------------------------------------------------------------------------
# install.packages(c("ggplot2", "svglite"))
suppressPackageStartupMessages({
  library(ggplot2)
  library(svglite)
})

# -----------------------------------------------------------------------------
# 1. Read local copies of the two CSVs (no internet).
# -----------------------------------------------------------------------------
person <- read.csv("data/pslm_person_subset.csv", stringsAsFactors = FALSE)
hh     <- read.csv("data/pslm_hh_subset.csv",     stringsAsFactors = FALSE)

# -----------------------------------------------------------------------------
# 2. Attach hhweight, prov_code, urban_rural to the person file by hhid.
# -----------------------------------------------------------------------------
hh_keep <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
dat <- merge(person, hh_keep, by = "hhid", all.x = TRUE)

# -----------------------------------------------------------------------------
# 3. Variant 1 = Punjab urban. Earners: 15-64 with earn_annual > 0.
# -----------------------------------------------------------------------------
earners <- subset(
  dat,
  prov_code == 2 & urban_rural == 2 &
    age >= 15 & age <= 64 &
    !is.na(earn_annual) & earn_annual > 0
)

# -----------------------------------------------------------------------------
# 4. The default figure: nothing added. No log scale, no theme, no labels.
# -----------------------------------------------------------------------------
p_default <- ggplot(earners, aes(age, earn_annual)) + geom_point()

# -----------------------------------------------------------------------------
# 5. Save as SVG via svglite.
# -----------------------------------------------------------------------------
ggsave("figures/default.svg", p_default, width = 7, height = 5)

message("Saved figures/default.svg  (n = ", nrow(earners), " earners)")
