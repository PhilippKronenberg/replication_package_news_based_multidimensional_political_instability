#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Main-text count and intensity figures
#
# Produces:
# - Outputs/Main/Figures/topic_intensity_by_year.pdf
# - Outputs/Main/Figures/country_intensity_by_year.pdf
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rm(list = ls())
cat("\014")

# Packages ----------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(lubridate)

# Setup -------------------------------------------------------------------
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

load(derived_path("intermediate", "prepared_data_NBS.rda"))
load(derived_path("final_data_NBS.rda"))
list2env(metadata, envir = .GlobalEnv)

factor_names <- c(
  "political_violence",
  "mass_civil_protest",
  "instability_of_regime",
  "instability_within_regime"
)

topic_labels <- c(
  political_violence = "Political Violence",
  mass_civil_protest = "Mass Civil Protest",
  instability_of_regime = "Instability of Regime",
  instability_within_regime = "Instability Within Regime"
)

base_df <- final_data_NBS %>%
  filter(list_element %in% factor_names) %>%
  mutate(
    list_element = trimws(tolower(as.character(list_element))),
    year = year(date)
  ) %>%
  group_by(country, year, list_element) %>%
  summarize(NBS_B = sum(NBS_B, na.rm = TRUE), .groups = "drop")

# Figure 1: topic intensity by year ---------------------------------------
topic_plot_df <- base_df %>%
  mutate(
    list_element = factor(list_element, levels = factor_names, labels = topic_labels)
  ) %>%
  group_by(list_element) %>%
  mutate(global_mean = mean(NBS_B, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(topic_intensity = (NBS_B / 17) / global_mean)

topic_intensity_plot <- ggplot(
  topic_plot_df,
  aes(x = year, y = topic_intensity, fill = country)
) +
  geom_bar(stat = "identity", position = "stack", alpha = 0.9) +
  facet_wrap(~ list_element, scales = "free_y") +
  labs(
    x = "Year",
    y = "Average Index B Value (Normalized Intensity)",
    fill = "Country"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(size = 18),
    axis.text.y = element_text(size = 18),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20),
    strip.text = element_text(size = 18, face = "bold"),
    legend.text = element_text(size = 18),
    legend.title = element_text(size = 20, face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  main_figure_path("topic_intensity_by_year.pdf"),
  plot = topic_intensity_plot,
  device = "pdf",
  width = 14,
  height = 10
)

# Figure 2: country intensity by year -------------------------------------
topic_means <- base_df %>%
  group_by(list_element) %>%
  summarize(global_mean = mean(NBS_B, na.rm = TRUE), .groups = "drop")

country_plot_df <- base_df %>%
  left_join(topic_means, by = "list_element") %>%
  mutate(
    country_intensity = (NBS_B / 4) / global_mean,
    list_element = factor(list_element, levels = factor_names, labels = topic_labels)
  ) %>%
  mutate(
    list_element = factor(
      list_element,
      levels = rev(c(
        "Political Violence",
        "Mass Civil Protest",
        "Instability Within Regime",
        "Instability of Regime"
      ))
    )
  )

country_intensity_plot <- ggplot(
  country_plot_df,
  aes(x = year, y = country_intensity, fill = list_element)
) +
  geom_bar(stat = "identity", position = "stack") +
  facet_wrap(~ country, scales = "free_y", ncol = 4) +
  scale_fill_manual(
    values = c(
      "Political Violence" = "#d73027",
      "Mass Civil Protest" = "#4575b4",
      "Instability Within Regime" = "#1a9850",
      "Instability of Regime" = "#fdae61"
    ),
    name = "Dimension",
    drop = FALSE
  ) +
  labs(
    x = "Year",
    y = "Average Index B Value (Normalized by Regional Dimension Mean)",
    fill = "Dimension"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(size = 18),
    axis.text.y = element_text(size = 18),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20),
    strip.text = element_text(size = 18, face = "bold"),
    legend.text = element_text(size = 18),
    legend.title = element_text(size = 20, face = "bold"),
    legend.position = "bottom"
  )

ggsave(
  main_figure_path("country_intensity_by_year.pdf"),
  plot = country_intensity_plot,
  device = "pdf",
  width = 14,
  height = 18
)
