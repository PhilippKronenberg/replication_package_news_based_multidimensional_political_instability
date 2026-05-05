#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Normalized NBS figures for the four instability dimensions
#
# Produces:
# - Outputs/Main/Figures/nbs_a_*_by_country.pdf
# - Outputs/Annex/Figures/nbs_ab_*_by_country.pdf
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Clean Console and Environment
rm(list = ls())
cat("\014")

# Packages ----------------------------------------------------------------

library(jsonlite)
library(ggplot2)
library(tidyverse)
library(dplyr)
library(xtable)
library(lubridate)
library(readxl)
library(purrr)
library(zoo)
library(tidyr) 

library(stringr)

# Load Functions ----------------------------------------------------------

# Load functions
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

# Define working directory
wd <- package_root()

# Load data ---------------------------------------------------------------

# Load the count data
load(derived_path("intermediate", "prepared_data_NBS.rda"))
load(derived_path("final_data_NBS.rda"))

# Save list elements as separate objects in the global environment
list2env(metadata, envir = .GlobalEnv)


# Plot Normalized NBS Indicators -----------------------------------------

topic_list <- c(
  "political_violence",
  "mass_civil_protest",
  "instability_within_regime",
  "instability_of_regime"
)
main_topics <- c(
  political_violence = "nbs_a_political_violence_by_country.pdf",
  mass_civil_protest = "nbs_a_mass_civil_protest_by_country.pdf",
  instability_within_regime = "nbs_a_instability_within_regime_by_country.pdf",
  instability_of_regime = "nbs_a_instability_of_regime_by_country.pdf"
)

appendix_topics <- c(
  political_violence = "nbs_ab_political_violence_by_country.pdf",
  mass_civil_protest = "nbs_ab_mass_civil_protest_by_country.pdf",
  instability_within_regime = "nbs_ab_instability_within_regime_by_country.pdf",
  instability_of_regime = "nbs_ab_instability_of_regime_by_country.pdf"
)

filtered_list <- list()
A_name <- "NBS_A"
B_name <- "NBS_B"

for (j in topic_list) {
  filtered_list[[j]] <- final_data_NBS %>%
    filter(list_element == j) %>%
    group_by(country) %>%
    mutate(!!sym(A_name) := idx.100(!!sym(A_name))) %>%
    ungroup()

  pp <- ggplot(filtered_list[[j]], aes(x = date, y = !!sym(A_name))) +
    geom_line(size = 0.6) +
    facet_wrap(~ country, scales = "free_y", ncol = 4) +
    labs(x = "Date", y = "Count") +
    theme_minimal() +
    theme(
      axis.text.x   = element_text(size = 14),
      axis.text.y   = element_text(size = 14),
      axis.title.x  = element_text(size = 16),
      axis.title.y  = element_text(size = 16),
      strip.text    = element_text(size = 16, face = "bold"),
      legend.text   = element_text(size = 14),
      legend.title  = element_text(size = 16, face = "bold"),
      legend.position = "bottom"
    )

  ggsave(
    ensure_parent_dir(main_figure_path(main_topics[[j]])),
    plot = pp,
    width = 14,
    height = 10
  )
}

for (j in topic_list) {
  filtered_list[[j]] <- final_data_NBS %>%
    filter(list_element == j) %>%
    group_by(country) %>%
    mutate(
      !!sym(A_name) := scale.0.100(!!sym(A_name)),
      !!sym(B_name) := scale.0.100(!!sym(B_name))
    ) %>%
    ungroup()

  pp_combined <- ggplot(filtered_list[[j]], aes(x = date)) +
    geom_line(aes(y = !!sym(A_name), color = "NBS_A"), size = 0.6, alpha = 0.6) +
    geom_line(aes(y = !!sym(B_name), color = "NBS_B"), size = 0.6, alpha = 0.6) +
    scale_color_manual(values = c("NBS_A" = "blue", "NBS_B" = "red")) +
    facet_wrap(~ country, scales = "free_y", ncol = 4) +
    labs(x = "Date", y = "Count", color = "Indicator") +
    theme_minimal() +
    theme(
      axis.text.x   = element_text(size = 14),
      axis.text.y   = element_text(size = 14),
      axis.title.x  = element_text(size = 16),
      axis.title.y  = element_text(size = 16),
      strip.text    = element_text(size = 16, face = "bold"),
      legend.text   = element_text(size = 14),
      legend.title  = element_text(size = 16, face = "bold"),
      legend.position = "bottom"
    )

  ggsave(
    ensure_parent_dir(annex_figure_path(appendix_topics[[j]])),
    plot = pp_combined,
    width = 14,
    height = 10
  )
}

