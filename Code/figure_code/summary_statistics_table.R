#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Summary statistics tables for the package appendix
#
# Produces:
# - Outputs/Annex/Tables/article_count_summary_statistics.tex
# - Outputs/Annex/Tables/dimension_article_count_summary_statistics.tex
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rm(list = ls())
cat("\014")

# Packages ----------------------------------------------------------------
library(dplyr)
library(purrr)
library(tidyr)
library(xtable)

# Setup -------------------------------------------------------------------
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

load(derived_path("prepared_data_NBS.rda"))
load(derived_path("final_data_NBS.rda"))
list2env(metadata, envir = .GlobalEnv)

summary_table_output <- ensure_parent_dir(
  annex_table_path("article_count_summary_statistics.tex")
)
summary_all_output <- ensure_parent_dir(
  annex_table_path("dimension_article_count_summary_statistics.tex")
)

topic_list <- c(
  "all_cnt",
  "political_instability",
  "political_violence",
  "mass_civil_protest",
  "instability_within_regime",
  "instability_of_regime"
)

topic_labels <- c(
  all_cnt = "All Articles",
  political_instability = "Political Instability",
  political_violence = "Political Violence",
  mass_civil_protest = "Mass Civil Protest",
  instability_within_regime = "Instability Within Regime",
  instability_of_regime = "Instability Of Regime"
)

# Helpers -----------------------------------------------------------------
append_all_articles <- function(final_data) {
  all_cnt_tab <- data_list_long$all_cnt$complete_tab %>%
    rename(country = Country, date = Date, count = Count) %>%
    mutate(list_element = "all_cnt")

  missing_cols <- setdiff(names(final_data), names(all_cnt_tab))
  for (col in missing_cols) {
    all_cnt_tab[[col]] <- NA
  }

  all_cnt_tab %>%
    select(all_of(names(final_data))) %>%
    bind_rows(final_data, .)
}

compute_country_summary <- function(df, topic) {
  df %>%
    filter(list_element == topic) %>%
    rename(Country = country, Date = date, Count = count) %>%
    group_by(Country) %>%
    summarize(
      average = round(mean(Count, na.rm = TRUE), 0),
      median = round(median(Count, na.rm = TRUE), 0),
      percentile10 = round(quantile(Count, 0.10, na.rm = TRUE), 0),
      percentile90 = round(quantile(Count, 0.90, na.rm = TRUE), 0),
      .groups = "drop"
    )
}

compute_summary_panel <- function(df, topic) {
  country_summary <- compute_country_summary(df, topic)

  summary_rows <- country_summary %>%
    summarize(
      average_mean = mean(average, na.rm = TRUE),
      average_median = median(average, na.rm = TRUE),
      average_min = min(average, na.rm = TRUE),
      average_max = max(average, na.rm = TRUE),
      median_mean = mean(median, na.rm = TRUE),
      median_median = median(median, na.rm = TRUE),
      median_min = min(median, na.rm = TRUE),
      median_max = max(median, na.rm = TRUE),
      percentile10_mean = mean(percentile10, na.rm = TRUE),
      percentile10_median = median(percentile10, na.rm = TRUE),
      percentile10_min = min(percentile10, na.rm = TRUE),
      percentile10_max = max(percentile10, na.rm = TRUE),
      percentile90_mean = mean(percentile90, na.rm = TRUE),
      percentile90_median = median(percentile90, na.rm = TRUE),
      percentile90_min = min(percentile90, na.rm = TRUE),
      percentile90_max = max(percentile90, na.rm = TRUE)
    ) %>%
    pivot_longer(
      cols = everything(),
      names_to = c("Statistic", "Metric"),
      names_sep = "_"
    ) %>%
    pivot_wider(names_from = Metric, values_from = value) %>%
    t() %>%
    as.data.frame()

  colnames(summary_rows) <- summary_rows[1, ]
  summary_rows <- summary_rows[-1, ] %>%
    mutate(Country = rownames(.)) %>%
    select(Country, everything()) %>%
    mutate(across(-Country, ~ round(as.numeric(.), 0)))

  colnames(country_summary) <- c("Country", "Mean", "Median", "p10", "p90")
  colnames(summary_rows) <- c("Country", "Mean", "Median", "p10", "p90")

  bind_rows(country_summary, summary_rows)
}

write_xtable <- function(df, output_path, caption, label, preamble_lines = NULL) {
  tex_table <- xtable(df, caption = caption, label = label, digits = 0)
  divider_position <- nrow(df) - 4

  if (!is.null(preamble_lines)) {
    cat(preamble_lines, file = output_path)
  }

  print(
    tex_table,
    file = output_path,
    include.rownames = FALSE,
    hline.after = c(-1, 0, divider_position, nrow(df)),
    add.to.row = list(
      pos = list(-1, 0, divider_position, nrow(df)),
      command = c(
        "\\hline  \\addlinespace[0.3em]\n",
        "\\addlinespace[0.3em]\n",
        "\\hline\n",
        "\\hline\n"
      )
    ),
    tabular.environment = "tabular",
    floating = FALSE,
    size = "scriptsize",
    sanitize.text.function = identity,
    caption.placement = "top",
    latex.environments = "center",
    booktabs = FALSE,
    table.placement = "!t",
    append = !is.null(preamble_lines)
  )
}

# Prepare data ------------------------------------------------------------
final_data_NBS <- append_all_articles(final_data_NBS)

# Table 1: all-articles summary -------------------------------------------
summary_table <- compute_summary_panel(final_data_NBS, "all_cnt")

write_xtable(
  df = summary_table,
  output_path = summary_table_output,
  caption = "Summary Statistics: Monthly Article Counts",
  label = "tab:summary_statistics",
  preamble_lines = c(
    "\\begin{table}[!t]\n",
    "  \\caption{Summary Statistics: Monthly Article Counts}\n",
    "  \\label{tab:summary_statistics}\n",
    "  \\centering\n",
    "  \\resizebox{10cm}{!}{%\n"
  )
)

# Table 2: topic-by-topic summary -----------------------------------------
summary_list <- lapply(topic_list, function(topic) {
  df <- compute_country_summary(final_data_NBS, topic)
  colnames(df)[-1] <- paste0(colnames(df)[-1], "_", topic)
  df
})

summary_table_all <- reduce(summary_list, full_join, by = "Country")

transposed_list <- map2(summary_list, topic_list, function(df, topic) {
  df %>%
    summarize(
      average_mean = mean(get(paste0("average_", topic)), na.rm = TRUE),
      average_median = median(get(paste0("average_", topic)), na.rm = TRUE),
      average_min = min(get(paste0("average_", topic)), na.rm = TRUE),
      average_max = max(get(paste0("average_", topic)), na.rm = TRUE),
      median_mean = mean(get(paste0("median_", topic)), na.rm = TRUE),
      median_median = median(get(paste0("median_", topic)), na.rm = TRUE),
      median_min = min(get(paste0("median_", topic)), na.rm = TRUE),
      median_max = max(get(paste0("median_", topic)), na.rm = TRUE),
      percentile10_mean = mean(get(paste0("percentile10_", topic)), na.rm = TRUE),
      percentile10_median = median(get(paste0("percentile10_", topic)), na.rm = TRUE),
      percentile10_min = min(get(paste0("percentile10_", topic)), na.rm = TRUE),
      percentile10_max = max(get(paste0("percentile10_", topic)), na.rm = TRUE),
      percentile90_mean = mean(get(paste0("percentile90_", topic)), na.rm = TRUE),
      percentile90_median = median(get(paste0("percentile90_", topic)), na.rm = TRUE),
      percentile90_min = min(get(paste0("percentile90_", topic)), na.rm = TRUE),
      percentile90_max = max(get(paste0("percentile90_", topic)), na.rm = TRUE)
    ) %>%
    pivot_longer(
      cols = everything(),
      names_to = c("Statistic", "Metric"),
      names_sep = "_"
    ) %>%
    pivot_wider(names_from = Metric, values_from = value) %>%
    t() %>%
    as.data.frame() %>%
    `colnames<-`(.[1, ]) %>%
    slice(-1) %>%
    mutate(Country = rownames(.)) %>%
    select(Country, everything()) %>%
    mutate(across(-Country, ~ round(as.numeric(.), 0))) %>%
    rename_with(~ paste0(., "_", topic), -Country)
})

transposed_table_all <- reduce(transposed_list, full_join, by = "Country")
combined_table <- bind_rows(summary_table_all, transposed_table_all)

column_group_header <- paste(
  "\\begin{table}[!t]\n",
  "  \\caption{Summary Statistics for all Dimensions: Monthly Article Counts}\n",
  "  \\label{tab:summary_statistics_all}\n",
  "  \\centering\n",
  "  \\resizebox{\\textwidth}{!}{%\n",
  "\\begin{tabular}{lrrrrrrrrrrrrrrrrrrrrrrrr}\n",
  "\\hline\n",
  "\\multicolumn{1}{c}{} & ",
  paste(sprintf("\\multicolumn{4}{c}{%s}", unname(topic_labels[topic_list])), collapse = " & "),
  " \\\\\n",
  "\\hline\n",
  "Country & Mean & Median & p10 & p90 & Mean & Median & p10 & p90 & Mean & Median & p10 & p90 & Mean & Median & p10 & p90 & Mean & Median & p10 & p90 & Mean & Median & p10 & p90 \\\\\n",
  "\\hline\n",
  sep = ""
)

write_xtable(
  df = combined_table,
  output_path = summary_all_output,
  caption = "Summary Statistics Across Topics",
  label = "tab:summary_statistics_all",
  preamble_lines = column_group_header
)
