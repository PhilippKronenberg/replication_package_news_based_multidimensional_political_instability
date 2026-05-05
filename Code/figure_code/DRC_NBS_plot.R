#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# DRC case-study figure
#
# Produces:
# - Outputs/Main/Figures/drc_normalized_nbs_events.pdf
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

library(readr)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(stringr)
library(scales)

# Load functions
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

# ---- 1) Load data ----
df <- read_csv(derived_path("final_data_NBS.csv"))

country <- "DR Congo"
shocks <- c(
  "political_violence",
  "mass_civil_protest",
  "instability_within_regime",
  "instability_of_regime"
)

# ---- 2) Filter + date + cut sample ----
drc <- df %>%
  filter(country == !!country, list_element %in% shocks) %>%
  mutate(date = as.Date(date)) %>%
  filter(date >= as.Date("2012-01-01"))

# ---- 3) Normalize within 2012–2024 window: max = 1 per series ----
drc <- drc %>%
  group_by(list_element) %>%
  mutate(NBS_norm = scale.0.100(NBS_B)/100) %>%
  # mutate(NBS_norm = ifelse(max(NBS_B, na.rm = TRUE) > 0,
  #                          NBS_B / max(NBS_B, na.rm = TRUE),
  #                          NBS_B)) %>%
  ungroup()

# ---- 4) Pretty labels: replace "_" with " " and Title Case ----
drc <- drc %>%
  mutate(list_element_pretty = str_to_title(str_replace_all(list_element, "_", " ")))

# ---- 5) Event dates (day-level) ----
events <- tibble::tribble(
  ~indicator,                  ~event,                        ~event_date,
  "political_violence",        "M23 takes Goma",              "2012-11-20",
  "political_violence",        "Beni massacres begin",        "2014-10-02",
  "political_violence",        "M23 takes Bunagana",          "2022-06-13",
  
  "mass_civil_protest",        "Jan 2015 protests begin",     "2015-01-19",
  "mass_civil_protest",        "Kinshasa protests",           "2016-09-19",
  "mass_civil_protest",        "Dec 2016 protests",           "2016-12-20",
  "mass_civil_protest",        "Catholic-led protests",       "2017-12-31",
  "mass_civil_protest",        "Catholic-led protests",       "2018-01-21",
  "mass_civil_protest",        "Catholic-led protests",       "2018-02-25",
  
  "instability_within_regime", "Kabila term ends (deadline)", "2016-12-19",
  "instability_within_regime", "Tshisekedi sworn in",         "2019-01-24",
  "instability_within_regime", "Coalition rupture announced", "2020-12-07",
  
  "instability_of_regime",     "Kabila term ends (deadline)", "2016-12-19",
  "instability_of_regime",     "2018 election day",           "2018-12-30",
  "instability_of_regime",     "Tshisekedi sworn in",         "2019-01-24",
  "instability_of_regime",     "2023 election day",           "2023-12-20"
) %>%
  mutate(
    event_date = as.Date(event_date),
    indicator_pretty = str_to_title(str_replace_all(indicator, "_", " "))
  )

# ---- 6) Build a consistent color mapping (shared by lines and vlines) ----
# ggplot assigns colors based on factor order, so set it explicitly.
pretty_levels <- str_to_title(str_replace_all(shocks, "_", " "))
drc <- drc %>%
  mutate(list_element_pretty = factor(list_element_pretty, levels = pretty_levels))

events <- events %>%
  mutate(indicator_pretty = factor(indicator_pretty, levels = pretty_levels))

# Use a discrete hue palette and freeze it to your levels
pal <- hue_pal()(length(pretty_levels))
names(pal) <- pretty_levels

# ---- 7) Plot ----
p <- ggplot(drc, aes(x = date, y = NBS_norm, color = list_element_pretty)) +
  geom_line(linewidth = 0.7) +
  geom_vline(
    data = events,
    aes(xintercept = event_date, color = indicator_pretty),
    linetype = "dashed",
    linewidth = 0.6,
    alpha = 0.85,
    inherit.aes = FALSE
  ) +
  scale_color_manual(values = pal, name = NULL) +
  scale_y_continuous(limits = c(-0.02, 1.05)) +
  labs(
    x = "Date",
    y = "Normalized NBS B (Max = 1)",
    #title = "Normalized News-Based Political Instability Indicators DRC (2012 2024)",
    #subtitle = "Max Within Series = 1; Dashed Lines = Dated Political Episodes"
  ) +
  theme_minimal(base_size = 12) +
  
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

print(p)

# ---- 8) Export ----
ggsave(
  filename = main_figure_path("drc_normalized_nbs_events.pdf"),
  plot = p,
  width = 12.2,
  height = 6.4,
  units = "in"
)


# Assumptions:
# 1) The CSV has columns: country, list_element, date, NBS_B
# 2) date is parseable as YYYY-MM-DD
# 3) Normalization is within the 2012–2024 cut, by series max
