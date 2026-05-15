#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Benchmark-to-NBS correlation summary table
#
# Produces:
# - Data/Derived/correlation_benchmark_rsui_table_new.rda
# - Data/Derived/mean_only_table_from_correlations.rda
# - Outputs/Annex/Tables/benchmark_mean_correlations.tex
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
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

# Load data ---------------------------------------------------------------
load(derived_path("prepared_data_NBS.rda"))
list2env(metadata, envir = .GlobalEnv)
load(derived_path("final_data_NBS.rda"))
load(derived_path("benchmark_long_table.rda"))
load(derived_path("benchmark_period_table.rda"))

# --- NEW: tag your own NBS dataset with source = "own"
final_data_NBS <- final_data_NBS %>%
  mutate(source = "own")

combined_data_rsui <- final_data_NBS

# Create correlation table ------------------------------------------------

country_to_iso3 <- c(
  "Benin" = "BEN",
  "Burkina Faso" = "BFA",
  "Cameroon" = "CMR",
  "Central African Republic" = "CAF",
  "Chad" = "TCD",
  "Cote d'Ivoire" = "CIV",
  "Democratic Republic of the Congo" = "COD",
  "Equatorial Guinea" = "GNQ",
  "Gabon" = "GAB",
  "Ghana" = "GHA",
  "Guinea-Bissau" = "GNB",
  "Mali" = "MLI",
  "Mauritania" = "MRT",
  "Niger" = "NER",
  "Nigeria" = "NGA",
  "Senegal" = "SEN",
  "Togo" = "TGO"
)

factor_names <- c(
  "political_violence",
  "mass_civil_protest",
  "instability_within_regime",
  "instability_of_regime"
)

excluded_event_types <- c(
  "Assassinations", "intviol", "intwar", "civviol", "Terror_Attacks",
  "civwar", "ethviol", "ethwar", "civtot", "inttot", "actotal",
  "Competitiveness of Nominating Process", "Composite Index", "Effectiveness of Legislature",
  "General Strikes", "Guerrilla Warfare", "Number of Seats", "Largest Party in Legislature",
  "Party Coalitions", "Party Legitimacy", "Purges", "Revolutions",
  "Seven-Year Average", "Seven-Year Total", "Size of Legislature (Lower House)",
  "Size of Legislature Scaled", "Weighted Conflict Index", "polity2",
  "gdelt.events.norm", "gdelt.articles.norm", "terror attack"
)

# Filter benchmark events
benchmark_long_table <- benchmark_long_table %>%
  filter(!(event_type %in% excluded_event_types))

make_event_type_short <- function(x) {
  x <- as.character(x)
  
  # --- 1) Normalize -------------------------------------------------------
  x <- stringr::str_trim(x)
  
  # remove leading icrg
  x <- stringr::str_remove(x, stringr::regex("^icrg[\\._]?", ignore_case = TRUE))
  
  # replace separators with space
  x <- stringr::str_replace_all(x, "[\\._]+", " ")
  
  # split camelCase / concatenated capitals
  x <- stringr::str_replace_all(x, "([a-z])([A-Z])", "\\1 \\2")
  x <- stringr::str_replace_all(x, "([A-Z])([A-Z][a-z])", "\\1 \\2")
  
  x <- stringr::str_squish(x)
  
  # --- 2) Dictionary-based replacements (FAST) ----------------------------
  replacements <- c(
    "\\bAnti Government\\b"              = "Anti-Gov.",
    "\\bViolence against civilians\\b"   = "Viol. against Civilians", 
    "\\bDemonstrations\\b"               = "Demonst.",
    "\\bGovernment\\b"                   = "Gov.",
    "\\bgovernment\\b"                   = "Gov.",
    "\\bLegislative\\b"                  = "Legis.",
    "\\bFractionalization\\b"            = "Frac.",
    "\\bEffectiveness\\b"                = "Effect.",
    "\\bRegulatory\\b"                   = "Reg.",
    "\\bVoiceand Accountability\\b"               = "Voice and Account.",
    "\\bControlof Corruption\\b"                   = "Control of Corrupt.",
    "\\bCorruption\\b"                   = "Corrupt.",
    "\\bStability\\b"                    = "Stab.",
    "\\bViolence\\b"                     = "Viol.",
    "\\bDevelopments\\b"                 = "Devel.",
    "\\bStrategic\\b"                    = "Strat.",
    "\\bStrat. developments\\b"                    = "Strat. Devel.",
    "\\bUncertainty\\b"                  = "Uncert.",
    "\\bInternal\\b"                     = "Int.",
    "\\bDisorder\\b"                     = "Disord.",
    "\\bTerrorism\\b"                    = "Terror.",
    "\\bDemocratic\\b"                   = "Dem.",
    "\\bPolitical\\b"                    = "Pol.",
    "\\bCompetitiveness\\b"              = "Compet.",
    "\\bRuleof Law\\b"                  = "Rule of Law",
    "\\bControl of\\b"                   = "Control of",
    "\\bintviol\\b"                      = "Int. Viol.",
    "\\bcivviol\\b"                      = "Civil Viol.",
    "\\bethviol\\b"                      = "Eth. Viol.",
    "\\bintwar\\b"                       = "Int. War",
    "\\bcivwar\\b"                       = "Civil War",
    "\\bethwar\\b"                       = "Eth. War",
    "\\bcivtot\\b"                       = "Civil War + Viol.",
    "\\binttot\\b"                       = "Int. War + Viol.",
    "\\bdemoc\\b"                        = "Democracy Index",
    "\\bautoc\\b"                        = "Autocracy Index",
    "\\bcivil disorder\\b"               = "Civil Disorder",    
    "\\bcivil war\\b"                    = "Civil War",
    "\\bcorruption index\\b"             = "Corruption Index",
    "\\belection index\\b"               = "Election Index", 
    "\\bgovernment index\\b"             = "Gov. Index", 
    "\\binternal conflict\\b"            = "Internal Conflict",    
    "\\bleadership index\\b"             = "Leadership Index",  
    "\\bterrorism\\b"                    = "Terrorism",  
    "Number of Seats, Largest Party in Legislature" = "Nr. Seats Largest Party",
    "Size of Legislature Scaled"                    = "Size of Leg.",
    "Majority Party Indicator"                      = "Maj. Party",
    "terrer attack"                                 = "Terror Attack",
    "gdelt articles norm"                           = "Articles Norm"
  )
  
  x <- stringr::str_replace_all(x, replacements)
  
  # final cleanup
  stringr::str_squish(x)
}

benchmark_long_table <- benchmark_long_table %>%
  mutate(event_type = make_event_type_short(event_type))

benchmark_period_table <- benchmark_period_table %>%
  mutate(event_type = make_event_type_short(event_type))


# --- NEW: mapping from benchmark event_type to source (benchmark inputs)
# benchmark_long_table has column "source" (confirmed)
event_source_map <- benchmark_long_table %>%
  distinct(event_type, source) %>%
  group_by(event_type) %>%
  summarise(Source = paste(sort(unique(source)), collapse = ", "), .groups = "drop")

# Step 1: Convert columns to numeric and preprocess
benchmark_long_table <- benchmark_long_table %>%
  mutate(count = as.numeric(count))

combined_data_rsui <- combined_data_rsui %>%
  filter(list_element %in% factor_names)

# Step 2: Identify overlapping date range per country
date_ranges <- benchmark_long_table %>%
  group_by(country) %>%
  summarise(
    min_date = max(
      min(date, na.rm = TRUE),
      min(combined_data_rsui$date[combined_data_rsui$country == unique(country)], na.rm = TRUE)
    ),
    max_date = min(
      max(date, na.rm = TRUE),
      max(combined_data_rsui$date[combined_data_rsui$country == unique(country)], na.rm = TRUE)
    ),
    .groups = "drop"
  )

# Step 3: Filter both datasets to matching date range per country
benchmark_filtered <- benchmark_long_table %>%
  inner_join(date_ranges, by = "country") %>%
  filter(date >= min_date & date <= max_date) %>%
  select(-min_date, -max_date)

rsui_filtered <- combined_data_rsui %>%
  select(country, date, NBS_A, NBS_B, list_element, source) %>%
  inner_join(date_ranges, by = "country") %>%
  filter(date >= min_date & date <= max_date) %>%
  select(-min_date, -max_date)

rsui_filtered <- rsui_filtered %>%
  dplyr::mutate(
    list_element = dplyr::recode(
      list_element,
      political_violence        = "Political Violence",
      mass_civil_protest        = "Mass Civil Protest",
      instability_within_regime = "Instability within Regime",
      instability_of_regime     = "Instability of Regime",
      .default = list_element
    )
  )

# --- NEW: add NBS_A series as additional benchmark "event types"
rsui_as_benchmark <- rsui_filtered %>%
  transmute(
    country    = country,
    date       = date,
    event_type = paste0(list_element),
    count      = NBS_B,
    source     = source   # will be "own"
  )

# Combine original benchmark events + synthetic NBS_A benchmark variables
# (keep existing columns; extra "source" column does not hurt)
benchmark_filtered <- bind_rows(benchmark_filtered, rsui_as_benchmark)

# --- NEW: extend event_source_map for synthetic NBS_A rows with Source = "own"
event_source_map <- bind_rows(
  event_source_map,
  tibble(
    event_type = paste0(factor_names),
    Source = "own"
  )
)

# --- Clean Source labels --------------------------------------------------
event_source_map <- event_source_map %>%
  mutate(
    Source = Source %>%
      str_replace("_.*$", "") %>%                          # drop everything after first "_"
      str_remove(regex("^df\\.", ignore_case = TRUE)) %>%  # remove leading "df."
      str_remove(regex("\\.idx$", ignore_case = TRUE)) %>% # remove trailing ".idx"
      toupper() %>%                                        # ALL CAPS
      str_squish()
  )




# Initialize list to store correlation matrices per country
correlation_matrices <- list()

# Loop over each country
for (cntry in unique(benchmark_filtered$country)) {
  
  bench_country <- benchmark_filtered %>% filter(country == cntry)
  rsui_country  <- rsui_filtered %>% filter(country == cntry)
  
  event_types   <- unique(bench_country$event_type)
  list_elements <- unique(rsui_country$list_element)
  
  cor_matrix <- matrix(
    NA,
    nrow = length(event_types),
    ncol = length(list_elements),
    dimnames = list(event_types, list_elements)
  )
  
  for (ev in event_types) {
    for (le in list_elements) {
      
      bench_subset <- bench_country %>% filter(event_type == ev)
      rsui_subset  <- rsui_country  %>% filter(list_element == le)
      
      merged_data <- inner_join(bench_subset, rsui_subset, by = "date")
      
      if (nrow(merged_data) > 1) {
        cor_matrix[ev, le] <- round(
          cor(merged_data$count, merged_data$NBS_B, use = "complete.obs"),
          2
        )
      }
    }
  }
  
  correlation_matrices[[cntry]] <- cor_matrix
}

# Get names of factors (columns)
column_names <- colnames(correlation_matrices[[1]])

# Get all unique event types across countries
all_event_types <- unique(unlist(map(correlation_matrices, rownames)))

# Function to extract a specific factor column into wide table (countries as columns)
extract_column <- function(column_name) {
  
  out <- map_dfr(names(correlation_matrices), function(country) {
    
    iso3 <- unname(country_to_iso3[country])
    if (is.na(iso3)) iso3 <- country
    
    tibble(
      event_type = rownames(correlation_matrices[[country]]),
      Value      = correlation_matrices[[country]][, column_name],
      Country    = iso3
    )
    
  }) %>%
    pivot_wider(names_from = Country, values_from = Value) %>%
    left_join(event_source_map, by = "event_type") %>%
    mutate(`Event Type` = str_replace_all(event_type, "_", " ")) %>%
    select(`Event Type`, Source, everything(), -event_type) %>%
    complete(
      `Event Type` = str_replace_all(all_event_types, "_", " "),
      fill = list(Value = NA)
    )
  
  # --- NEW: mean over all country columns (numeric columns), ignoring NAs
  out <- out %>%
    mutate(
      MEAN = rowMeans(dplyr::select(., where(is.numeric)), na.rm = TRUE)
    )
  
  out
}


# Create list of tables, one per factor
correlation_benchmark_rsui_table <- setNames(lapply(column_names, extract_column), column_names)

# Save list of tables as rda
save(
  correlation_benchmark_rsui_table,
  file = derived_path("correlation_benchmark_rsui_table_new.rda")
)

# Create mean table -------------------------------------------------------



# --- NEW: build a summary table with only MEAN from each factor table ------

mean_only_table <- purrr::imap(correlation_benchmark_rsui_table, function(df, nm) {
  df %>%
    dplyr::select(`Event Type`, Source, MEAN) %>%
    dplyr::rename(!!nm := MEAN)   # column name = list element name (the string used to name the tables)
}) %>%
  purrr::reduce(dplyr::full_join, by = c("Event Type", "Source"))

# Optional: order columns nicely
mean_only_table <- mean_only_table %>%
  dplyr::select(`Event Type`, Source, dplyr::all_of(names(correlation_benchmark_rsui_table)))

# (Optional) save as .rda
save(
  mean_only_table,
  file = derived_path("mean_only_table_from_correlations.rda")
)


# --- NEW: round and export MEAN-only table to LaTeX ------------------------


save_latex_mean_table <- function(df, table_name) {
  
  tab_dir <- annex_table_path()
  dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
  file_path <- file.path(tab_dir, paste0(table_name, ".tex"))
  
  # round numeric columns to 2 decimals
  df2 <- df %>%
    mutate(across(where(is.numeric), ~ round(.x, 2)))
  
  xt <- xtable(
    df2,
    caption = "Mean Correlations across Countries",
    label   = paste0("tab:", table_name)
  )
  
  latex_code <- capture.output(
    print(
      xt,
      include.rownames       = FALSE,
      floating               = TRUE,
      table.placement        = "htbp",
      caption.placement      = "top",
      booktabs               = TRUE,
      sanitize.text.function = identity,
      na.string              = "{}"
    )
  )
  
  # column spec: Event Type + Source (ll) + numeric columns
  n_numeric <- sum(sapply(df2, is.numeric))
  latex_code <- sub(
    "^\\\\begin\\{tabular\\}\\{.*\\}$",
    paste0("\\\\begin{tabular}{ll*{", n_numeric, "}{r}}"),
    latex_code
  )
  
  # add \scriptsize and \centering
  begin_idx <- grep("^\\\\begin\\{table\\}", latex_code)
  if (length(begin_idx) == 1) {
    latex_code <- append(
      latex_code,
      values = c("\\scriptsize", "\\centering"),
      after  = begin_idx
    )
  }
  
  out <- c(
    "% LaTeX Table",
    "% Mean correlations across countries",
    latex_code
  )
  
  writeLines(out, file_path)
}

# Desired row order
rows_order <- c(
  "Political Violence",
  "Mass Civil Protest",
  "Instability within Regime",
  "Instability of Regime",
  "Civil Unrest",
  "Internal Conflict",
  "Coups",
  "Annual Coups",
  "Civil War",
  "Viol.",
  "Viol. against Civilians",
  "Ethnic Viol.", 
  "Battles",
  "Explosions",
  "Terrorism",
  "Protest",
  "Protests",
  "Riots",
  "Pol. Sanctions",
  "Corruption Index",
  "Gov. Crises",
  "Years in Office",
  "Legis. Frac.",
  "Democracy Index",
  "Gov. Effect.",
  "Party in Power",
  "Maj. Party",
  "Pol. Stab. No Viol.",
  "Reg. Quality",
  "Rule of Law",
  "Voice and Account."
)

mean_only_table_filtered <- mean_only_table %>%
  dplyr::filter(`Event Type` %in% rows_order) %>%
  dplyr::mutate(
    `Event Type` = factor(`Event Type`, levels = rows_order)
  ) %>%
  dplyr::arrange(`Event Type`) %>%
  dplyr::mutate(`Event Type` = as.character(`Event Type`)) %>%
  dplyr::mutate(across(where(is.numeric), ~ round(.x, 2)))

# Export
save_latex_mean_table(
  mean_only_table_filtered,
  table_name = "benchmark_mean_correlations"
)


