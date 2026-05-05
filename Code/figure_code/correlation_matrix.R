#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Correlation heatmaps for appendix
#
# Produces:
# - Outputs/Annex/Figures/monthly_correlation_heatmaps.pdf
# - Outputs/Annex/Figures/annual_correlation_heatmaps.pdf
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rm(list = ls())
cat("\014")

# Packages ----------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(ggpubr)
library(scales)
library(tidyr)
library(xtable)

# Setup -------------------------------------------------------------------
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

load(derived_path("intermediate", "prepared_data_NBS.rda"))
load(derived_path("final_data_NBS.rda"))
list2env(metadata, envir = .GlobalEnv)

topic_list <- c(
  "political_violence",
  "mass_civil_protest",
  "instability_within_regime",
  "instability_of_regime"
)

ordered_names <- c(
  "BEN", "BFA", "CMR", "CAF", "TCD", "CIV", "COD", "GNQ", "GAB",
  "GHA", "GNB", "MLI", "MRT", "NER", "NGA", "SEN", "TGO"
)

highlight_top10_with_regions <- function(value, row_name, col_name, threshold) {
  if (value == "") {
    return("")
  }

  row_region <- country_to_region$region[country_to_region$country_code == row_name]
  col_region <- country_to_region$region[country_to_region$country_code == col_name]
  exceeds_threshold <- !is.na(as.numeric(value)) && as.numeric(value) >= threshold
  same_region <- !is.na(row_region) && !is.na(col_region) && row_region == col_region

  if (same_region && exceeds_threshold) {
    sprintf("\\cellcolor[gray]{0.8}{\\textbf{\\textcolor{red}{%.2f}}}", as.numeric(value))
  } else if (same_region) {
    sprintf("\\textcolor{red}{%.2f}", as.numeric(value))
  } else if (exceeds_threshold) {
    sprintf("\\cellcolor[gray]{0.8}{\\textbf{%.2f}}", as.numeric(value))
  } else {
    sprintf("%.2f", as.numeric(value))
  }
}

build_matrix_list <- function(data_frequency = c("monthly", "annual")) {
  data_frequency <- match.arg(data_frequency)
  matrix_list <- list()

  for (topic in topic_list) {
    data_tab <- final_data_NBS %>%
      filter(list_element == topic) %>%
      rename(Country = country, Count = count, Date = date) %>%
      select(Country, Date, NBS_B, list_element)

    if (data_frequency == "annual") {
      data_tab <- data_tab %>%
        mutate(Year = lubridate::year(Date)) %>%
        group_by(Country, Year, list_element) %>%
        summarize(NBS_B = sum(NBS_B, na.rm = TRUE), .groups = "drop")

      wide_data <- data_tab %>%
        pivot_wider(names_from = Country, values_from = NBS_B) %>%
        select(Year, list_element, sort(names(.)[!names(.) %in% c("Year", "list_element")]))
    } else {
      wide_data <- data_tab %>%
        pivot_wider(names_from = Country, values_from = NBS_B) %>%
        select(Date, list_element, sort(names(.)[!names(.) %in% c("Date", "list_element")]))
    }

    wide_data[is.na(wide_data)] <- 0

    cor_matrix <- wide_data %>%
      select(-(1:2)) %>%
      cor(use = "complete.obs")

    cor_matrix <- cor_matrix[order(rownames(cor_matrix)), order(colnames(cor_matrix))]
    cor_matrix <- round(cor_matrix, 2)
    cor_matrix[lower.tri(cor_matrix, diag = TRUE)] <- NA

    cor_matrix_df <- as.data.frame(cor_matrix)
    cor_matrix_df[is.na(cor_matrix_df)] <- ""
    colnames(cor_matrix_df) <- country_to_region$country_code[match(colnames(cor_matrix_df), country_to_region$country_name)]
    rownames(cor_matrix_df) <- country_to_region$country_code[match(rownames(cor_matrix_df), country_to_region$country_name)]

    threshold <- quantile(as.numeric(as.matrix(cor_matrix)), 0.90, na.rm = TRUE)
    cor_matrix_formatted <- matrix(nrow = nrow(cor_matrix_df), ncol = ncol(cor_matrix_df))

    for (ii in seq_len(nrow(cor_matrix_df))) {
      for (jj in seq_len(ncol(cor_matrix_df))) {
        cor_matrix_formatted[ii, jj] <- highlight_top10_with_regions(
          cor_matrix_df[ii, jj],
          rownames(cor_matrix_df)[ii],
          colnames(cor_matrix_df)[jj],
          threshold
        )
      }
    }

    cor_matrix_formatted <- as.data.frame(cor_matrix_formatted)
    colnames(cor_matrix_formatted) <- colnames(cor_matrix_df)
    rownames(cor_matrix_formatted) <- rownames(cor_matrix_df)

    matrix_list[[paste0("Matrix_", topic)]] <- cor_matrix_formatted
  }

  matrix_list
}

plot_heatmaps <- function(matrix_list, output_file) {
  all_plots <- list()

  for (mat_name in names(matrix_list)) {
    cor_matrix_df <- matrix_list[[mat_name]]
    cor_matrix_df_num <- suppressWarnings(apply(cor_matrix_df, 2, as.numeric))
    rownames(cor_matrix_df_num) <- rownames(cor_matrix_df)
    cor_matrix_df_num <- cor_matrix_df_num[ordered_names, ordered_names]

    cor_table <- as.data.frame(cor_matrix_df_num) %>%
      mutate(Series = rownames(cor_matrix_df_num)) %>%
      pivot_longer(cols = -Series, names_to = "Lag", values_to = "Correlation") %>%
      drop_na(Correlation) %>%
      mutate(
        Series = factor(Series, levels = ordered_names),
        Lag = factor(Lag, levels = ordered_names)
      )

    pretty_name <- tools::toTitleCase(gsub("_", " ", mat_name))

    all_plots[[mat_name]] <- ggplot(cor_table, aes(x = Lag, y = Series, fill = Correlation)) +
      geom_tile(color = "white") +
      geom_text(aes(label = round(Correlation, 1)), color = "black", size = 3) +
      scale_fill_gradient2(
        low = "blue",
        mid = "white",
        high = "red",
        midpoint = 0,
        limits = c(-1, 1),
        oob = squish
      ) +
      labs(
        title = pretty_name,
        x = "Country (Column)",
        y = "Country (Row)",
        fill = "Correlation"
      ) +
      theme_minimal(base_size = 10) +
      theme(
        axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
        axis.text.y = element_text(size = 12),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14),
        legend.text = element_text(size = 12),
        legend.title = element_text(size = 14, face = "bold"),
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        panel.grid = element_blank(),
        plot.margin = margin(10, 10, 10, 10)
      )
  }

  final_plot <- ggarrange(
    plotlist = all_plots,
    ncol = 2,
    nrow = 2,
    common.legend = TRUE,
    legend = "bottom",
    widths = c(1, 1),
    heights = c(1, 1),
    align = "hv"
  )

  ggsave(output_file, plot = final_plot, width = 10, height = 9)
}

plot_heatmaps(
  build_matrix_list("monthly"),
  ensure_parent_dir(annex_figure_path("monthly_correlation_heatmaps.pdf"))
)

plot_heatmaps(
  build_matrix_list("annual"),
  ensure_parent_dir(annex_figure_path("annual_correlation_heatmaps.pdf"))
)
