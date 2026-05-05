#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Main R entrypoint for the formal replication package
#
# Runs the data-ingestion, data-preparation, benchmark-harmonization,
# figure-generation, and table-generation scripts that feed the packaged
# outputs under `Outputs/`.
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Clean Console and Environment
rm(list = ls())
cat("\014")


# Preliminaries -----------------------------------------------------------

# Set working directory to the replication package root
source(file.path("Code", "helpers.R"))
use_package_root()
wd <- package_root()


# Run files ---------------------------------------------------------------

# Run read data
source(file.path("Code", "1_read_data.R"))

# Run data preparation
source(file.path("Code", "2_data_preparation.R"))

# Run benchmark data
source(file.path("Code", "3_benchmark_data.R"))

# Source table
source(file.path("Code", "figure_code", "source_table.R"))

# Summary statistics table
source(file.path("Code", "figure_code", "summary_statistics_table.R"))

# Benchmark correlation tables
source(file.path("Code", "figure_code", "benchmark_indicator_correlation_table.R"))

# Appendix map
source(file.path("Code", "figure_code", "africa_map.R"))


# Run plots and tables ----------------------------------------------------

# Run normalization plot
source(file.path("Code", "figure_code", "normalization_plot.R"))

# Run country count plot
source(file.path("Code", "figure_code", "country_count_plot.R"))

# DRC event figure
source(file.path("Code", "figure_code", "DRC_NBS_plot.R"))

# Appendix correlation heatmaps
source(file.path("Code", "figure_code", "correlation_matrix.R"))

# Appendix contagion networks
source(file.path("Code", "figure_code", "contagion_plot.R"))

# Additional non-package generators are preserved in
# `../non_package_materials/Code/`.





