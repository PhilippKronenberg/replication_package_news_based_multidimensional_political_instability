# Replication Package: News-Based Multidimensional Political Instability

## Overview

This repository is the formal replication package for the paper on news-based multidimensional political instability in West and Central Africa. The package contains the code, data, and manuscript-facing outputs required for the documented replication workflow.

The canonical entrypoints are:

- `Code/main.R` for the R workflow
- `Code/run_all.m` for the MATLAB workflow

## Folder Structure

```text
replication_package_news_based_multidimensional_political_instability/
├── README.md
├── LICENSE
├── Code/
│   ├── main.R
│   ├── run_all.m
│   ├── 1_read_data.R
│   ├── 2_data_preparation.R
│   ├── 3_benchmark_data.R
│   ├── functions.R
│   ├── helpers.R
│   ├── figure_code/
│   └── external/
├── Data/
│   ├── Raw/
│   │   ├── public/
│   │   └── restricted/
│   └── Derived/
└── Outputs/
    ├── Main/
    │   ├── Figures/
    │   └── Tables/
    └── Annex/
        ├── Figures/
        └── Tables/
```

## Requirements

- R version `4.5.2`
- Python version `3.14.4`
- MATLAB release `R2025a`
- R packages used in the scripts under `Code/`, including `jsonlite`, `ggplot2`, `tidyverse`, `dplyr`, `xtable`, `lubridate`, `readxl`, `purrr`, `zoo`, `tidyr`, `writexl`, `rnaturalearth`, and `sf`
- Sufficient local storage for the bundled raw inputs and derived files

Runtime:
Verified on `2026-05-04`: `Code/main.R` completed successfully in approximately 9 minutes on the local machine used for package preparation. `Code/run_all.m` completed successfully in approximately 1 minute after resetting the MATLAB `R2025a` user-preferences folder and letting MATLAB recreate it.

Memory:
Verified on `2026-05-04`: the successful package test run was executed on a machine with approximately `29.7 GB` of installed RAM (`27.6 GiB`). No memory bottleneck was encountered during the verified R and MATLAB runs.

## Using the Public GitHub Repository

The package is also maintained as a public GitHub repository:

- [PhilippKronenberg/replication_package_news_based_multidimensional_political_instability](https://github.com/PhilippKronenberg/replication_package_news_based_multidimensional_political_instability)

To work directly from Git:

```bash
git clone https://github.com/PhilippKronenberg/replication_package_news_based_multidimensional_political_instability.git
cd replication_package_news_based_multidimensional_political_instability
```

After cloning, run the workflows from the repository root so the relative paths in `Code/main.R`, `Code/run_all.m`, and the output folders resolve correctly.

## Setup Instructions

1. Open an R session and set the working directory to the repository root.
2. Ensure the required R packages are installed.
3. Confirm the bundled raw inputs are present under:
   `Data/Raw/public/benchmark_data/`
   `Data/Raw/public/VAR/monthly/Democratic_Republic_of_the_Congo.csv`
   `Data/Raw/restricted/factiva_api/Results_new/`
   `Data/Raw/restricted/factiva_lookup/`
   `Data/Raw/restricted/factiva_rtf_exports/`
4. If you want to refresh the IRF figures, ensure MATLAB can run `Code/run_all.m`.

## Instructions for Replicators

Run the R workflow from the package root:

```r
source("Code/main.R")
```

Run the MATLAB workflow from the package root:

```matlab
run("Code/run_all.m")
```

The R workflow reads and harmonizes the newspaper-count inputs, prepares the monthly NBS series, constructs benchmark comparison data, and writes the package outputs. The MATLAB workflow refreshes the IRF figures used in the DRC case study.

## Code Description

- `Code/main.R`: canonical R entrypoint; sources the package scripts in replication order.
- `Code/run_all.m`: canonical MATLAB entrypoint; runs the external VAR workflow and refreshes the package IRF figures.
- `Code/1_read_data.R`: reads the Factiva API results and lookup files, harmonizes raw inputs, and writes `Data/Derived/intermediate/raw_data_NBS.rda`.
- `Code/2_data_preparation.R`: prepares the article-count panel, creates normalized NBS series, writes the core derived data objects, and produces `country_normalization_reference_counts.pdf` and `aggregate_normalization_reference_counts.pdf`.
- `Code/3_benchmark_data.R`: harmonizes the benchmark datasets listed in `Data/Raw/public/benchmark_data/benchmark_data_websites.txt` and writes `Data/Derived/benchmark_data.rda`, `benchmark_long_table.rda`, `benchmark_period_table.rda`, and their `.csv` counterparts.
- `Code/figure_code/source_table.R`: generates `Outputs/Main/Tables/newspaper_source_summary.tex`.
- `Code/figure_code/summary_statistics_table.R`: generates `Outputs/Annex/Tables/article_count_summary_statistics.tex` and `dimension_article_count_summary_statistics.tex`.
- `Code/figure_code/benchmark_indicator_correlation_table.R`: generates `Outputs/Annex/Tables/benchmark_mean_correlations.tex`.
- `Code/figure_code/africa_map.R`: generates `Outputs/Annex/Figures/africa_map.pdf`.
- `Code/figure_code/normalization_plot.R`: generates the package normalization figures for the four instability dimensions.
- `Code/figure_code/country_count_plot.R`: generates `topic_intensity_by_year.pdf` and `country_intensity_by_year.pdf`.
- `Code/figure_code/DRC_NBS_plot.R`: generates `Outputs/Main/Figures/drc_normalized_nbs_events.pdf`.
- `Code/figure_code/correlation_matrix.R`: generates `Outputs/Annex/Figures/monthly_correlation_heatmaps.pdf` and `annual_correlation_heatmaps.pdf`.
- `Code/figure_code/contagion_plot.R`: generates the four appendix contagion network figures.
- `Code/external/caldara_iacoviello_2022/`: contains the external MATLAB support code used by `Code/run_all.m`; temporary estimation caches are recreated during runtime and are not kept as part of the formal package.

## List of Exhibits

| Exhibit | Output file | Script |
|---|---|---|
| Summary of Newspaper Sources | `Outputs/Main/Tables/newspaper_source_summary.tex` | `Code/figure_code/source_table.R` |
| Country-Specific Normalization Reference Counts | `Outputs/Main/Figures/country_normalization_reference_counts.pdf` | `Code/2_data_preparation.R` |
| Political Violence Index per Country | `Outputs/Main/Figures/nbs_a_political_violence_by_country.pdf` | `Code/figure_code/normalization_plot.R` |
| Mass Civil Protest Index per Country | `Outputs/Main/Figures/nbs_a_mass_civil_protest_by_country.pdf` | `Code/figure_code/normalization_plot.R` |
| Instability of the Regime Index per Country | `Outputs/Main/Figures/nbs_a_instability_of_regime_by_country.pdf` | `Code/figure_code/normalization_plot.R` |
| Instability Within the Regime Index per Country | `Outputs/Main/Figures/nbs_a_instability_within_regime_by_country.pdf` | `Code/figure_code/normalization_plot.R` |
| Political Instability Article Counts by Topic | `Outputs/Main/Figures/topic_intensity_by_year.pdf` | `Code/figure_code/country_count_plot.R` |
| Political Instability Article Counts by Country | `Outputs/Main/Figures/country_intensity_by_year.pdf` | `Code/figure_code/country_count_plot.R` |
| Normalized DRC NBS Indicators | `Outputs/Main/Figures/drc_normalized_nbs_events.pdf` | `Code/figure_code/DRC_NBS_plot.R` |
| DRC Impulse Responses | `Outputs/Main/Figures/IRF_Democratic_Republic_of_the_Congo_GPRBASELINE.png` | `Code/run_all.m` |
| Africa Sample Map | `Outputs/Annex/Figures/africa_map.pdf` | `Code/figure_code/africa_map.R` |
| Aggregate Normalization Reference Counts | `Outputs/Annex/Figures/aggregate_normalization_reference_counts.pdf` | `Code/2_data_preparation.R` |
| Four appendix normalization figures | `Outputs/Annex/Figures/nbs_ab_*_by_country.pdf` | `Code/figure_code/normalization_plot.R` |
| Correlation heatmaps | `Outputs/Annex/Figures/monthly_correlation_heatmaps.pdf`, `annual_correlation_heatmaps.pdf` | `Code/figure_code/correlation_matrix.R` |
| Four contagion network figures | `Outputs/Annex/Figures/contagion_network_geo_*.pdf` | `Code/figure_code/contagion_plot.R` |
| DRC robustness IRFs | `Outputs/Annex/Figures/IRF_Democratic_Republic_of_the_Congo_GPRBASELINE_endo_com.png`, `IRF_Democratic_Republic_of_the_Congo_GPRBASELINE_no_com.png` | `Code/run_all.m` |
| Summary Statistics: Monthly Article Counts | `Outputs/Annex/Tables/article_count_summary_statistics.tex` | `Code/figure_code/summary_statistics_table.R` |
| Mean Correlations across Countries | `Outputs/Annex/Tables/benchmark_mean_correlations.tex` | `Code/figure_code/benchmark_indicator_correlation_table.R` |
| Summary Statistics for All Dimensions | `Outputs/Annex/Tables/dimension_article_count_summary_statistics.tex` | `Code/figure_code/summary_statistics_table.R` |

## Data Availability

Availability of data and code: all data required to reproduce the documented package outputs are included in this repository.

The authors had legitimate access to the bundled data and have included the materials required for this replication package. Code is distributed under the package [LICENSE](C:/Users/kphilipp/GitHub/newspaper_sentiment/replication_package_news_based_multidimensional_political_instability/LICENSE). Bundled third-party data remain attributable to their original producers and should be cited accordingly when reused.

### Newspaper Data

- Dow Jones Factiva article-query results used to construct the monthly newspaper-based political instability series are bundled under `Data/Raw/restricted/factiva_api/Results_new/`.
- Factiva lookup tables, source lists, and taxonomy support files are bundled under `Data/Raw/restricted/factiva_lookup/`.
- Supporting raw Factiva RTF export archives are bundled under `Data/Raw/restricted/factiva_rtf_exports/`.
- The NBS construction relies on a fixed set of country-coverage, source-selection, and newspaper-sample choices documented in the project materials and reflected in the packaged source table.

### Benchmark Data Sources

The benchmark inputs are bundled under `Data/Raw/public/benchmark_data/`. Source URLs documented in `Data/Raw/public/benchmark_data/benchmark_data_websites.txt` include:

- ACLED: `https://acleddata.com/curated-data-files/`
- Afrobarometer: `https://www.afrobarometer.org/data/merged-data/`
- Barrett et al. civil unrest materials: `https://www.sciencedirect.com/science/article/pii/S0304387822000803`
- CNTS: `https://www.cntsdata.com/licenses`
- Center for Systemic Peace: `https://www.systemicpeace.org/inscrdata.html`
- Database of Political Institutions: `https://datacatalog.worldbank.org/dataset/wps2283-database-political-institutions`
- Gallup World Poll access points: `https://wbglibrary.worldbank.org/find/databases`
- GDELT: `https://www.gdeltproject.org/`
- ICRG: `https://www.prsgroup.com/explore-our-products/icrg/`
- Powell and Thyne coup data: `https://www.uky.edu/~clthyn2/coup_data/home.htm`
- UCDP: `https://ucdp.uu.se/downloads/`
- Worldwide Governance Indicators: `https://www.worldbank.org/en/publication/worldwide-governance-indicators`
- World Handbook of Political Indicators IV: `https://sociology.osu.edu/worldhandbook/world-handbook-information-frequently-asked-questions`
- World Uncertainty Index: `https://worlduncertaintyindex.com/data/`

The benchmark materials bundled in `Data/Raw/public/benchmark_data/` were accessed in `2025`.

### VAR and Supplementary Macro Inputs

- Country-level macro and VAR inputs used by the MATLAB workflow are bundled under `Data/Raw/public/VAR/monthly/`.
- The formal package keeps only the DRC monthly input file needed by `Code/run_all.m`.

Macro-data source details recorded in the project bibliography:

- IMF Data Portal: exchange rates, commodity export price indices, CPI, and policy rates. Source URL: `https://data.imf.org`. Bibliography entry: `IMFDataPortal`. Access date recorded in the bibliography: `12 November 2025`.
- Global Scale Nightlight Time Series Dataset: nighttime lights. Source URL: `https://nightlight.eoatlas.org`. Bibliography entry: `Najjar2024Nightlight`. Access date recorded in the bibliography: `1 October 2025`.
- World Development Indicators DataBank: included in the bibliography as `WorldBank2025WDI` with source URL `http://databank.worldbank.org/data/reports.aspx?source=world-development-indicators` and access date `1 October 2025`.

## Notes

- The packaged figures and tables are stored directly under `Outputs/`.
- `Data/Raw/public/benchmark_data/` has been trimmed to the exact files read by `Code/3_benchmark_data.R`.
- `Data/Raw/public/VAR/` has been trimmed to the single DRC monthly CSV used by the MATLAB entrypoint.
- `Data/Derived/` keeps only the derived objects consumed by the active package scripts.
- The `Data/Raw/restricted/` folder name is retained for path compatibility with the Factiva-related scripts.
- Version check on `2026-05-04`: `R 4.5.2`, `Python 3.14.4`, and MATLAB install folder `R2025a` were detected locally.
- Replication check on `2026-05-04`: `Code/main.R` and `Code/run_all.m` both completed successfully after the package-minimization cleanup. During package preparation, the MATLAB `R2025a` user-preferences folder was reset and backed up so MATLAB could recreate a clean startup state.
