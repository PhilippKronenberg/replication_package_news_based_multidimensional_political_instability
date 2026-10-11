# Replication Package: News-Based Multidimensional Political Instability

**Authors:** Philipp Kronenberg (KOF, ETH Zurich), Kabinet Kaba (World Bank), Pierre Jean-Claude Mandon (World Bank, corresponding author)

## Overview

This repository is the formal replication package for the paper on news-based multidimensional political instability in West and Central Africa. The package contains the code, data, and manuscript-facing outputs required for the documented replication workflow.

The canonical entrypoints are:

- `Code/main.R` for the R workflow
- `Code/run_all.m` for the MATLAB workflow
- `Section_4.3/NBS_Master.do` for the Stata workflow of the firm-level application (Section 4.3, Tables 3 to 7)

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
├── Outputs/
│   ├── Main/
│   │   ├── Figures/
│   │   └── Tables/
│   └── Annex/
│       ├── Figures/
│       └── Tables/
└── Section_4.3/
    ├── README.md
    ├── NBS_Master.do
    ├── Data/
    └── Tables/
```

## Requirements

- R version `4.5.2`
- Python version `3.14.4`
- MATLAB release `R2025a`
- Stata `17` or later, for `Section_4.3/` only (user packages `kountry`, `outreg`, `estout`, installed automatically by the do-file)
- R packages used in the scripts under `Code/`: `countrycode`, `dplyr`, `geomtextpath`, `ggplot2`, `ggpubr`, `haven`, `jsonlite`, `lubridate`, `purrr`, `readr`, `readxl`, `rnaturalearth`, `rnaturalearthdata`, `scales`, `sf`, `stringr`, `tidyr`, `tidyverse`, `xtable`, and `zoo`

  These do not have to be installed by hand. `Code/main.R` loads the full list through `ensure_packages()` in `Code/helpers.R` and installs whatever is missing from CRAN; every individual script does the same for the subset it needs, so the scripts can also be run one at a time. To install nothing automatically, set the environment variable `NBS_INSTALL_MISSING=FALSE` before running — the scripts then stop with an error listing the packages to install manually.
- Storage: about 0.5 GB for the repository with its bundled inputs and outputs, plus about 1.2 GB for the Enterprise Surveys file that replicators download for `Section_4.3/`

Technology environment:
Operating system: Windows 11. Memory: approximately `29.7 GB` RAM (see below).

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

1. Open an R session and set the working directory to the repository root. All scripts resolve their paths relative to that root, so they have to be started from there (`source("Code/main.R")`, not from inside `Code/`).
2. The required R packages are installed automatically on first run; see the note under Requirements if you prefer to install them yourself.
3. Confirm the bundled raw inputs are present under:
   `Data/Raw/public/benchmark_data/`
   `Data/Raw/public/VAR/monthly/Democratic_Republic_of_the_Congo.csv`
   `Data/Raw/restricted/factiva_api/Results_Factiva_API/`
   `Data/Raw/restricted/factiva_lookup/`
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

### Firm-Level Application (Section 4.3)

The firm-level application, which links the annual NBS indicators to firm performance in the World Bank Enterprise Surveys (Tables 3 to 7), is a separate Stata workflow in `Section_4.3/`. It is self-contained and does not depend on running the R or MATLAB workflows first. Before running it, download the Enterprise Surveys microdata, which are not included in this repository (see Data Availability), then set `$root` in `Section_4.3/NBS_Master.do` to the `Section_4.3` folder and run:

```stata
do "Section_4.3/NBS_Master.do"
```

See [`Section_4.3/README.md`](Section_4.3/README.md) for the input data, run switches, and specification.

## Code Description

- `Code/main.R`: canonical R entrypoint; sources the package scripts in replication order.
- `Code/run_all.m`: canonical MATLAB entrypoint; runs the external VAR workflow and refreshes the package IRF figures.
- `Code/1_read_data.R`: reads the Factiva API results and lookup files, harmonizes raw inputs, and writes `Data/Derived/raw_data_NBS.rda`.
- `Code/2_data_preparation.R`: prepares the article-count panel, creates normalized NBS series, writes the core derived data objects, and produces `country_normalization_reference_counts.pdf` and `aggregate_normalization_reference_counts.pdf`.
- `Code/3_benchmark_data.R`: harmonizes the benchmark datasets listed in `Data/Raw/public/benchmark_data/benchmark_data_websites.txt` and writes `Data/Derived/benchmark_data.rda` and `benchmark_long_table.rda`.
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
| DRC Impulse Responses | `Outputs/Main/Figures/IRF_DRC_baseline.png` | `Code/run_all.m` |
| Africa Sample Map | `Outputs/Annex/Figures/africa_map.pdf` | `Code/figure_code/africa_map.R` |
| Aggregate Normalization Reference Counts | `Outputs/Annex/Figures/aggregate_normalization_reference_counts.pdf` | `Code/2_data_preparation.R` |
| Four appendix normalization figures | `Outputs/Annex/Figures/nbs_ab_*_by_country.pdf` | `Code/figure_code/normalization_plot.R` |
| Correlation heatmaps | `Outputs/Annex/Figures/monthly_correlation_heatmaps.pdf`, `annual_correlation_heatmaps.pdf` | `Code/figure_code/correlation_matrix.R` |
| Four contagion network figures | `Outputs/Annex/Figures/contagion_network_geo_*.pdf` | `Code/figure_code/contagion_plot.R` |
| DRC robustness IRFs | `Outputs/Annex/Figures/IRF_DRC_endo_com.png`, `IRF_DRC_no_com.png` | `Code/run_all.m` |
| Summary Statistics: Monthly Article Counts | `Outputs/Annex/Tables/article_count_summary_statistics.tex` | `Code/figure_code/summary_statistics_table.R` |
| Mean Correlations across Countries | `Outputs/Annex/Tables/benchmark_mean_correlations.tex` | `Code/figure_code/benchmark_indicator_correlation_table.R` |
| Summary Statistics for All Dimensions | `Outputs/Annex/Tables/dimension_article_count_summary_statistics.tex` | `Code/figure_code/summary_statistics_table.R` |
| Tables 3 to 7: Firm-level descriptive statistics and regressions | `Section_4.3/Tables/Table3_*` to `Table7_*` (`.tex`, `.doc`, `.rtf`) | `Section_4.3/NBS_Master.do` |

Tables that do not show analysis results and are written by hand in the manuscript, not produced by the code:

- Table 2 (Summary Macroeconomic Variables): describes the VAR data sources.
- Table B.4 (Search Criteria): lists the Factiva search terms and filters.
- Table B.5 (Major Political Instability Events): a narrative event chronology.

## Data Availability

### Statement

All input data needed to reproduce the outputs of the R and MATLAB workflows are in this repository. One input for the firm-level application (`Section_4.3/`) is not: the World Bank Enterprise Surveys microdata (dataset 17 below). Its terms of use forbid redistribution. Replicators can get it free of charge after registering.

The authors had legitimate access to every dataset listed here. The code is distributed under the package [LICENSE](LICENSE). That license does not cover third-party data. Each dataset stays under its provider's license, listed below, and must be cited as shown when reused.

The table summarizes the inputs that the package code does not create. Full details for each dataset follow. The access types are the World Bank README Generator categories:

- **Open:** publicly available and redistributable.
- **Accessible:** publicly downloadable, but redistribution not permitted.
- **Limited-access:** requires purchase or human approval.
- **Restricted:** access granted directly to the authors under custom terms.

| # | Dataset | Location in package | Provided | Access type |
|---|---|---|---|---|
| 1 | Dow Jones Factiva article counts | `Data/Raw/restricted/factiva_api/Results_Factiva_API/` | Yes (aggregated counts only, with permission) | Limited-access |
| 2 | Dow Jones Factiva lookup codes | `Data/Raw/restricted/factiva_lookup/` | Yes (with permission) | Limited-access |
| 3 | ACLED | `Data/Raw/public/benchmark_data/ACLED/` | Yes (with permission) | Accessible |
| 4 | Barrett et al. (2022) social unrest events | `Data/Raw/public/benchmark_data/Barret et al/` | Yes | Open |
| 5 | Cross-National Time-Series Data Archive (CNTS) | `Data/Raw/public/benchmark_data/CNTS Data Archive/` | Yes (with permission) | Limited-access |
| 6 | CSP Coups d'État | `Data/Raw/public/benchmark_data/CSP Database/Center for Systemic Peace, Coups d'Etat, 1946-2021/` | Yes | Open |
| 7 | Polity5 | `Data/Raw/public/benchmark_data/CSP Database/Polity5 Project, .../` | Yes | Open |
| 8 | Database of Political Institutions 2012 | `Data/Raw/public/benchmark_data/Database of Political Institutions (World Bank)/` | Yes | Open |
| 9 | Gallup World Poll (Gallup Analytics) | `Data/Raw/public/benchmark_data/GALLUP/` | Yes (with permission) | Limited-access |
| 10 | International Country Risk Guide (ICRG) | `Data/Raw/public/benchmark_data/ICRG sample (not free)/` | Yes (with permission) | Limited-access |
| 11 | Powell and Thyne coups | `Data/Raw/public/benchmark_data/powell_thyne_coups/` | Yes | Open |
| 12 | UCDP Ethnic One-Sided Violence | `Data/Raw/public/benchmark_data/UCDP dataset/` | Yes | Open |
| 13 | Worldwide Governance Indicators | `Data/Raw/public/benchmark_data/World Bank Worldwide Governance Indicators/` | Yes | Open |
| 14 | World Handbook of Political Indicators IV | `Data/Raw/public/benchmark_data/World Handbook of Political Indicators IV (WHIV)/` | Yes | Open |
| 15 | DRC monthly VAR dataset (IMF, Banque Centrale du Congo, nighttime lights) | `Data/Raw/public/VAR/monthly/` | Yes | Open |
| 16 | World Development Indicators (firm-level application) | `Section_4.3/Data/WDI/` | Yes | Open |
| 16b | IMF World Economic Outlook, GDP deflator | `Section_4.3/Data/WDI/WDI_GDP_Deflator1.xlsx` | Yes | Open |
| 17 | World Bank Enterprise Surveys | `Section_4.3/Data/WBES/` | **No** | Accessible |

Some files in the package are derived from the inputs above by the authors' own processing. The NBS indicators are one example: `Section_4.3/Data/NBS data/NBS_indicators.xlsx` and `NBS_Data.dta` are annual aggregates of the series that the R workflow builds from datasets 1–2. Derived files like these are not listed as separate inputs.

---

### Newspaper Data

#### 1. Dow Jones Factiva article counts

- **Filename(s):** `Data/Raw/restricted/factiva_api/Results_Factiva_API/` contains 85 JSON files in 28 numbered query subfolders (`1/` … `28/`), named `analytics_<YYYYMMDD>_<HHMMSS>.json`. Each subfolder holds one query; the query definitions are listed in the header of `Code/1_read_data.R`. Read by `Code/1_read_data.R`.
- **Source:** Dow Jones & Company, Factiva. The files were retrieved through the Factiva Analytics API.
- **URL / access instructions:** The data require a Factiva subscription with API access (https://www.dowjones.com/professional/factiva/). They are monthly article counts from 1 January 1990 onward for 17 countries. The Factiva region codes are `nigea`, `eqgna`, `niger`, `camer`, `cafr`, `ghana`, `maurtn`, `gabon`, `upvola`, `icst`, `gubi`, `mali`, `chad`, `togo`, `benin`, `seneg`, `zaire`. The source set is `grdn`, `wp`, `afpr`, `deuen`, `bbcmnf`, `j`, `lba`, `aprs`, `xnews`, `ajazen`, `voa`, `ec`. These are the 12 English-language outlets in Table 1 of the paper, chosen using the Global Media Index for Africa 2024. The subject tags to include and exclude and the keyword strings for each dimension are given in full in Table B.4 of the paper. The 28 queries are listed at the top of `Code/1_read_data.R`. A third party with Factiva API access can resubmit these queries. Results may differ slightly because Factiva updates its archive over time. Contact: Pierre Mandon, `pmandon@worldbank.org`.
- **Access date:** July 2025, per the API timestamps in the file names (6–10 July 2025).
- **Citation:** Dow Jones & Company. (2025). *Factiva* [Database; Factiva Analytics API, monthly article counts]. Retrieved July 2025 from https://www.dowjones.com/professional/factiva/
- **License:** Proprietary; access requires a Dow Jones Factiva subscription. The package redistributes only aggregated monthly article counts. It contains no article text, headlines, or other licensed content. The authors' Factiva license permits redistribution of these aggregated counts as part of this replication package. Further redistribution or reuse is subject to Dow Jones Factiva terms.
- **Access type:** Limited-access (purchase of a Factiva subscription with API access).
- **License URL:** none public; governed by the Dow Jones Factiva subscription agreement.

#### 2. Dow Jones Factiva lookup codes

- **Filename(s):** `Data/Raw/restricted/factiva_lookup/All Active FA Sources 8-22-22.CSV` (list of Factiva sources) and `Data/Raw/restricted/factiva_lookup/regions.csv` (Factiva region codes and descriptions).
- **Source:** Dow Jones & Company, Factiva.
- **URL / access instructions:** Factiva subscribers can download both files from the Factiva Developer Platform under the taxonomy/lookup codes section (https://developer.dowjones.com/). Contact: Pierre Mandon, `pmandon@worldbank.org`.
- **Access date:** August 2022 (both files; the source list is dated 22 August 2022 in its file name).
- **Citation:** Dow Jones & Company. (2022). *Factiva source list and region taxonomy codes* [Data set]. Retrieved August 2022 from https://developer.dowjones.com/
- **License:** Proprietary; Factiva subscription. Reference metadata only, with no article content. The authors' Factiva license permits redistribution of these lookup files as part of this replication package. Further redistribution or reuse is subject to Dow Jones Factiva terms.
- **Access type:** Limited-access (Factiva subscription).
- **License URL:** none public; governed by the Dow Jones Factiva subscription agreement.

### Benchmark Data

All benchmark inputs are read by `Code/3_benchmark_data.R`. The provider URLs are also listed in `Data/Raw/public/benchmark_data/benchmark_data_websites.txt`.

#### 3. ACLED

- **Filename(s):** `Data/Raw/public/benchmark_data/ACLED/df_acled_in.rda`. The authors made this R extract from the ACLED Africa event file `Africa_1997-2025_Jan17.csv` by parsing dates and adding ISO3 codes; the code is commented out at the top of the ACLED section in `Code/3_benchmark_data.R`. The full CSV is not included because of its size.
- **Source:** Armed Conflict Location & Event Data (ACLED).
- **URL / access instructions:** https://acleddata.com/curated-data-files/. Register for a free ACLED account, then download the curated regional file for Africa covering 1997 to January 2025. Variables used: `event_date`, `country`, `event_type`, `sub_event_type`.
- **Access date:** January 2025, per the file name (17 January 2025).
- **Citation:** Raleigh, C., Linke, A., Hegre, H., & Karlsen, J. (2010). Introducing ACLED: An Armed Conflict Location and Event Dataset. *Journal of Peace Research*, 47(5), 651–660. https://doi.org/10.1177/0022343310378914. Data: ACLED, Africa curated data file, accessed 17 January 2025, https://acleddata.com.
- **License:** Free for registered users under the ACLED Terms of Use (https://acleddata.com/terms-of-use/). The authors' ACLED access permits redistribution of this extract as part of this replication package. Further redistribution or reuse is subject to the ACLED Terms of Use; other users must obtain the data from ACLED directly.
- **Access type:** Accessible (free registration; redistribution not permitted without permission).
- **License URL:** https://acleddata.com/terms-of-use/

#### 4. Barrett et al. (2022) social unrest events

- **Filename(s):** `Data/Raw/public/benchmark_data/Barret et al/events.rdata`.
- **Source:** Barrett, Appendino, Nguyen, and de Leon Miranda (IMF), from the replication materials of their *Journal of Development Economics* article.
- **URL / access instructions:** https://www.sciencedirect.com/science/article/pii/S0304387822000803, under the article's supplementary/replication materials. The file is the monthly country-level significant-unrest event panel (object `events.out`). The Reported Social Unrest Index is also published by the IMF at https://www.imf.org/en/Publications/WP/Issues/2020/08/07/Measuring-Social-Unrest-Using-Media-Reports-49544.
- **Access date:** January 2025.
- **Citation:** Barrett, P., Appendino, M., Nguyen, K., & de Leon Miranda, J. (2022). Measuring social unrest using media reports. *Journal of Development Economics*, 158, 102924. https://doi.org/10.1016/j.jdeveco.2022.102924
- **License:** Publicly downloadable, free to use with citation.
- **Access type:** Open.
- **License URL:** none stated by the provider; free use with citation of Barrett et al. (2022).

#### 5. Cross-National Time-Series Data Archive (CNTS)

- **Filename(s):** `Data/Raw/public/benchmark_data/CNTS Data Archive/2023_Edition_CNTSDATA.xlsx`.
- **Source:** Databanks International (Arthur S. Banks).
- **URL / access instructions:** https://www.cntsdata.com/licenses. Purchase a license and download the 2023 edition. Variables used: the domestic conflict (`domestic*`), legislative (`legis*`), and political (`polit*`) series, annual.
- **Access date:** January 2025.
- **Citation:** Banks, A. S., & Wilson, K. A. (2023). *Cross-National Time-Series Data Archive* (2023 ed.). Databanks International. https://www.cntsdata.com (cited in the paper as Banks and Wilson, 2013).
- **License:** Commercial license (Databanks International). The authors' license permits inclusion of the file in this replication package. Further redistribution or reuse requires a CNTS license.
- **Access type:** Limited-access (purchase of a license).
- **License URL:** https://www.cntsdata.com/licenses

#### 6. Center for Systemic Peace, Coups d'État 1946–2021

- **Filename(s):** `Data/Raw/public/benchmark_data/CSP Database/Center for Systemic Peace, Coups d'Etat, 1946-2021/CSPCoupsAnnualv2021.xls`.
- **Source:** Center for Systemic Peace (CSP), Integrated Network for Societal Conflict Research (INSCR).
- **URL:** https://www.systemicpeace.org/inscrdata.html, then "Coups d'État, 1946–2021", annual country file (Excel).
- **Access date:** January 2025.
- **Citation:** Marshall, M. G., & Marshall, D. R. (2022). *Coup d'État Events, 1946–2021* [Data set]. Center for Systemic Peace. https://www.systemicpeace.org/inscrdata.html
- **License:** Free for non-commercial research use with attribution (CSP terms of use).
- **Access type:** Open.
- **License URL:** https://www.systemicpeace.org/inscrdata.html (terms of use stated on the download page).

#### 7. Polity5

- **Filename(s):** `Data/Raw/public/benchmark_data/CSP Database/Polity5 Project, Political Regime Characteristics and Transitions, 1800-2018/p5v2018.xls`.
- **Source:** Center for Systemic Peace, Polity5 Project.
- **URL:** https://www.systemicpeace.org/inscrdata.html, then "Polity5 Annual Time-Series, 1946–2018" (Excel). Variables used: `democ`, `autoc`, `polity2`.
- **Access date:** January 2025.
- **Citation:** Marshall, M. G., & Gurr, T. R. (2020). *Polity5: Political Regime Characteristics and Transitions, 1800–2018* [Data set]. Center for Systemic Peace. https://www.systemicpeace.org/inscrdata.html
- **License:** Free for non-commercial research use with attribution (CSP terms of use).
- **Access type:** Open.
- **License URL:** https://www.systemicpeace.org/inscrdata.html (terms of use stated on the download page).

#### 8. Database of Political Institutions (DPI 2012)

- **Filename(s):** `Data/Raw/public/benchmark_data/Database of Political Institutions (World Bank)/dpi2012.xls`.
- **Source:** World Bank, Development Research Group.
- **URL:** https://datacatalog.worldbank.org/dataset/wps2283-database-political-institutions, file `DPI2012.xls`. Variables used: `yrsoffc`, `prtyin`, `govfrac`, `frac`, `maj`.
- **Access date:** January 2025.
- **Citation:** Beck, T., Clarke, G., Groff, A., Keefer, P., & Walsh, P. (2001). New tools in comparative political economy: The Database of Political Institutions. *World Bank Economic Review*, 15(1), 165–176. https://doi.org/10.1093/wber/15.1.165. Data: Database of Political Institutions 2012, World Bank.
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0), per the World Bank Data Catalog.
- **Access type:** Open.
- **License URL:** https://creativecommons.org/licenses/by/4.0/

#### 9. Gallup World Poll (Gallup Analytics)

- **Filename(s):** `Data/Raw/public/benchmark_data/GALLUP/GallupAnalytics_Export_20240823_141734.xlsx`. It has four sheets: "Approval of Country's Leadershi", "Confidence in National Governme", "Corruption in Government", and "Honesty of Elections".
- **Source:** Gallup, Inc., Gallup World Poll, accessed through the World Bank Group Library subscription to Gallup Analytics.
- **URL / access instructions:** Institutional subscription required; World Bank staff can use https://wbglibrary.worldbank.org/find/databases, then Gallup Analytics. Export the annual country-level percentages for the four indicators above, for all available years, for the 17 sample countries.
- **Access date:** August 2024 (23 August 2024, per the export timestamp in the file name).
- **Citation:** Gallup, Inc. (2024). *Gallup World Poll* [Data set; Gallup Analytics]. Retrieved 23 August 2024 from https://www.gallup.com/analytics/318875/global-research.aspx. Survey methodology: Tortora, R. D., Srinivasan, R., & Esipova, N. (2010). The Gallup World Poll. In *Survey Methods in Multinational, Multiregional, and Multicultural Contexts* (pp. 535–543). Wiley.
- **License:** Proprietary; subscription required. The file contains country-level aggregates only. The authors' access through the World Bank Group subscription permits their inclusion in this replication package. Further redistribution or reuse requires a Gallup Analytics subscription.
- **Access type:** Limited-access (institutional subscription).
- **License URL:** none public; governed by the World Bank Group's Gallup Analytics subscription agreement.

#### 10. International Country Risk Guide (ICRG)

- **Filename(s):** `Data/Raw/public/benchmark_data/ICRG sample (not free)/Barrett Replication Code/ICRG_CountryData.csv`.
- **Source:** The PRS Group, International Country Risk Guide. The file was obtained from the replication materials of Barrett et al. (2022) (dataset 4).
- **URL / access instructions:** https://www.prsgroup.com/explore-our-products/icrg/. A paid subscription is needed for the monthly political risk components. Alternatively, the file is in the Barrett et al. (2022) replication materials (see dataset 4).
- **Access date:** January 2025.
- **Citation:** The PRS Group. *International Country Risk Guide* [Data set]. https://www.prsgroup.com/explore-our-products/icrg/. Methodology: Howell, L. D. (2011). *International Country Risk Guide Methodology*. East Syracuse, NY: PRS Group.
- **License:** Commercial license (The PRS Group). The file is redistributed here as obtained from the Barrett et al. (2022) replication materials, with the authors' permission to include it in this replication package. Further redistribution or reuse requires an ICRG subscription.
- **Access type:** Limited-access (purchase of a subscription).
- **License URL:** none public; governed by The PRS Group subscription terms.

#### 11. Powell and Thyne coups

- **Filename(s):** `Data/Raw/public/benchmark_data/powell_thyne_coups/powell_thyne_coups_final.txt`, version `V2024.01.29`.
- **Source:** Jonathan Powell and Clayton Thyne, University of Kentucky.
- **URL:** https://www.uky.edu/~clthyn2/coup_data/home.htm, file "powell_thyne_coups_final.txt" (tab-delimited). Variables used: `country`, `year`, `month`, `coup`.
- **Access date:** January 2025.
- **Citation:** Powell, J. M., & Thyne, C. L. (2011). Global instances of coups from 1950 to 2010: A new dataset. *Journal of Peace Research*, 48(2), 249–259. https://doi.org/10.1177/0022343310397436
- **License:** Freely available for research use with citation.
- **Access type:** Open.
- **License URL:** none stated by the provider; free use with citation of Powell and Thyne (2011).

#### 12. UCDP Ethnic One-Sided Violence (EOSV) dataset

- **Filename(s):** `Data/Raw/public/benchmark_data/UCDP dataset/The Ethnic One-Sided Violence (EOSV) Dataset/EOSV Dataset.dta`.
- **Source:** Uppsala Conflict Data Program (UCDP), Department of Peace and Conflict Research, Uppsala University.
- **URL:** https://ucdp.uu.se/downloads/, then "Ethnic One-Sided Violence Dataset" (Stata). Variables used: `Year`, `BestFatalityEstimate`, `Location`.
- **Access date:** January 2025.
- **Citation:** Fjelde, H., Hultman, L., Schubiger, L. I., Cederman, L.-E., Hug, S., & Sollenberg, M. (2021). Introducing the Ethnic One-Sided Violence dataset. *Conflict Management and Peace Science*, 38(1), 109–126. https://doi.org/10.1177/0738894219863256
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0), per UCDP.
- **Access type:** Open.
- **License URL:** https://creativecommons.org/licenses/by/4.0/

#### 13. Worldwide Governance Indicators (WGI)

- **Filename(s):** `Data/Raw/public/benchmark_data/World Bank Worldwide Governance Indicators/The Worldwide Governance Indicators.xlsx`, with one sheet per dimension: `VoiceandAccountability`, `Political StabilityNoViolence`, `GovernmentEffectiveness`, `RegulatoryQuality`, `RuleofLaw`, `ControlofCorruption`.
- **Source:** World Bank.
- **URL:** https://www.worldbank.org/en/publication/worldwide-governance-indicators, full dataset (Excel), 1996–2022 (2023 update). Variable used: the `Estimate` column of each sheet.
- **Access date:** January 2025.
- **Citation:** Kaufmann, D., Kraay, A., & Mastruzzi, M. (2011). The Worldwide Governance Indicators: Methodology and analytical issues. *Hague Journal on the Rule of Law*, 3(2), 220–246. https://doi.org/10.1017/S1876404511200046. Data: Worldwide Governance Indicators, 2023 update, www.govindicators.org.
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0).
- **Access type:** Open.
- **License URL:** https://creativecommons.org/licenses/by/4.0/

#### 14. World Handbook of Political Indicators IV (WHIV)

- **Filename(s):** `Data/Raw/public/benchmark_data/World Handbook of Political Indicators IV (WHIV)/WHIV (Daily-csv).csv`.
- **Source:** J. Craig Jenkins, Charles Lewis Taylor, and co-authors, The Ohio State University.
- **URL:** https://sociology.osu.edu/worldhandbook, daily event file (CSV). Variables used: `eventdate`, `eventform`, `tgtloc_wdi`.
- **Access date:** January 2025.
- **Citation:** Jenkins, J. C., Taylor, C. L., Abbott, M., Maher, T. V., & Peterson, L. (2012). *The World Handbook of Political Indicators IV*. Mershon Center for International Security Studies, The Ohio State University. https://sociology.osu.edu/worldhandbook
- **License:** Publicly downloadable, free to use with citation.
- **Access type:** Open.
- **License URL:** none stated by the provider; free use with citation of Jenkins et al. (2012).

### VAR Data (MATLAB workflow)

#### 15. DRC monthly VAR dataset

- **Filename(s):** `Data/Raw/public/VAR/monthly/Democratic_Republic_of_the_Congo.csv`. The authors compiled this file outside the package code; it is read by `Code/run_all.m`. It covers January 2012 to May 2024 and has the columns `CPI`, `Exchange Rate`, `Interest Rate`, `Nighttime Light`, `Commodity Price Index`, and the four NBS series. The NBS columns are output of this package, computed from datasets 1–2. The other columns come from the three sources below. They are described in Table 2 of the paper.
- **(a) IMF Data Portal: CPI, exchange rate, commodity export price index**
  - Source: International Monetary Fund.
  - URL: https://data.imf.org. Monthly series for the Democratic Republic of the Congo (IMF dataset and series key):

    | Column | IMF dataset | Series key | Description |
    |---|---|---|---|
    | `CPI` | `IMF.STA:CPI` (5.0.0), Consumer Price Index | `COD.CPI._T.SRP_YOY_PCH_PA_PT.M` | All items, 2010 = 100, period average, year-over-year percent change |
    | `Exchange Rate` | `IMF.STA:ER` (4.0.1), Exchange Rates | `COD.XDC_USD.PA_RT.M` | Domestic currency per US dollar, period average; the authors converted it to the period-over-period percent change |
    | `Commodity Price Index` | `IMF.RES:CTOT` (5.0.0), Commodity Terms of Trade | `COD.CEPI_CTOTX_GDP.R_RW_IX.M` | Commodity export price index, individual commodities weighted by the ratio of exports to GDP, June 2012 = 100, rolling weights |
  - Access date: November 2025 for CPI and exchange rate (12 November 2025); October 2025 for the commodity price index (6 October 2025, per the timestamp of the downloaded file).
  - Citation: International Monetary Fund. (2025). *IMF Data Portal* [Data set]. Retrieved 12 November 2025 from https://data.imf.org (cited in the paper as IMF, 2025).
  - License: Free; reuse and redistribution with attribution under the IMF Copyright and Usage terms.
  - Access type: Open.
  - License URL: https://www.imf.org/external/terms.htm
- **(b) Banque Centrale du Congo: policy rate**
  - Source: Banque Centrale du Congo (BCC). The IMF monetary statistics (`IMF.STA:MFS_IR`, monetary policy-related rate) have no DRC series. The `Interest Rate` column is therefore built from the BCC's history of policy-rate decisions ("Historique des taux") and the BCC communiqué of 8 August 2023. Each decision's rate is carried forward to every month until the next change.
  - URL: https://www.bcc.cd/statistiques/secteur-monetaire/taux-interet ("Taux de politique monétaire", series "Taux directeur BCC"). The page has the full monthly series from January 1991, exportable as CSV or XLSX. The 8 August 2023 decision of the Comité de Politique Monétaire raised the rate from 11% to 25%.
  - Access date: November 2025.
  - Citation: Banque Centrale du Congo. *Taux d'intérêt: Taux directeur de la BCC, série mensuelle* [Data set]. https://www.bcc.cd/statistiques/secteur-monetaire/taux-interet. Banque Centrale du Congo (2023). *Communiqué du Comité de Politique Monétaire du 8 août 2023*. Kinshasa.
  - License: Publicly available official statistics from the Banque Centrale du Congo, free to use with attribution.
  - Access type: Open.
  - License URL: none stated by the provider; free use with attribution to the Banque Centrale du Congo.
- **(c) Global Scale Nightlight Time Series Dataset: nighttime lights**
  - Source: Global Scale Nightlight Time Series Dataset, A. Najjar, Earth Observation Atlas. The dataset is built from VIIRS (SNPP) monthly composites and published as a GitHub repository.
  - URL: https://github.com/eoatlas/nightlight (homepage https://nightlight.eoatlas.org). Monthly median nighttime-light intensity for the Democratic Republic of the Congo, national aggregate (ADM0), January 2012 – May 2024, which is the dataset's full coverage. The authors deseasonalized the series before adding it to the file.
  - Access date: October 2025 (1 October 2025).
  - Citation: Najjar, A. (2024). *Global Scale Nightlight Time Series Dataset* [Data set]. Earth Observation Atlas. Retrieved 1 October 2025 from https://github.com/eoatlas/nightlight
  - License: Creative Commons Attribution 4.0 (CC BY 4.0); free to use with attribution.
  - Access type: Open.
  - License URL: https://creativecommons.org/licenses/by/4.0/

### Firm-Level Application (Section 4.3)

#### 16. World Development Indicators (firm-level application)

- **Filename(s):** `Section_4.3/Data/WDI/WDI_GDP_growth1.xlsx`, `WDI_GDP1.xlsx`, `WDI_GDPper1.xlsx`, `WDI_GDPper_growth1.xlsx`, `WDI_Exchange_Rate1.xlsx`. The `.dta` files of the same names and `WDI_Database.dta` are created from these workbooks by `NBS_Master.do`. (`WDI_GDP_Deflator1.xlsx` sits in the same folder but comes from the IMF; see dataset 16b.)
- **Source:** World Bank, World Development Indicators.
- **URL / access instructions:** https://databank.worldbank.org/source/world-development-indicators. Select all countries, the years 1960–2024, and the following series, then export in wide format with years as columns:
  - `NY.GDP.MKTP.KD.ZG`, GDP growth (annual %), in `WDI_GDP_growth1`
  - `NY.GDP.MKTP.KD`, GDP (constant 2015 US$), in `WDI_GDP1`
  - `NY.GDP.PCAP.KN`, GDP per capita (constant LCU), in `WDI_GDPper1`
  - `NY.GDP.PCAP.KD.ZG`, GDP per capita growth (annual %), in `WDI_GDPper_growth1`
  - `PA.NUS.FCRF`, official exchange rate (LCU per US$, period average), in `WDI_Exchange_Rate1`
- **Access date:** October 2025 (1 October 2025).
- **Citation:** World Bank. (2025). *World Development Indicators* [Data set]. Retrieved 1 October 2025 from https://databank.worldbank.org/source/world-development-indicators
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0).
- **Access type:** Open.
- **License URL:** https://creativecommons.org/licenses/by/4.0/

#### 16b. IMF World Economic Outlook: GDP deflator (firm-level application)

- **Filename(s):** `Section_4.3/Data/WDI/WDI_GDP_Deflator1.xlsx`. The workbook keeps its `WDI_` prefix because `NBS_Master.do` reads it by that name. `NBS_Master.do` converts it to `WDI_GDP_Deflator1.dta`.
- **Source:** International Monetary Fund, World Economic Outlook database.
- **URL / access instructions:** https://www.imf.org/en/Publications/WEO/weo-database/2024/April (April 2024 edition). Choose "By Countries", select all countries, select the series `NGDP_D` (Gross domestic product, deflator, index), and select the years 1980–2029. Export, then reshape to wide format with a `Country` column and one column per year named `x1980` … `x2029`.
- **Access date:** October 2025 (1 October 2025).
- **Citation:** International Monetary Fund. (2024). *World Economic Outlook Database*, April 2024 edition [Data set]. https://www.imf.org/en/Publications/WEO/weo-database/2024/April
- **License:** Free; reuse and redistribution with attribution under the IMF Copyright and Usage terms.
- **Access type:** Open.
- **License URL:** https://www.imf.org/external/terms.htm

#### 17. World Bank Enterprise Surveys (not included)

- **Filename(s):** `Section_4.3/Data/WBES/New_Comprehensive_May_5_2025.dta`. **Not included in the package.** The derived analysis file `Section_4.3/Data/Finale_Data/Finale_Data.dta` is firm-level microdata and is not included either; `NBS_Master.do` rebuilds it from the downloaded file.
- **Source:** World Bank, Enterprise Analysis Unit.
- **URL / access instructions:** https://www.enterprisesurveys.org. Register for a free account and sign in. Then, under the "Combined Data" tab, download the harmonized global raw-data file (Stata format), release of 5 May 2025. This release covers survey years 2006–2025. The 2025 waves are Poland and Trinidad and Tobago only, so the most recent waves for the sample countries date from 2023–2024. Save it unchanged as `Section_4.3/Data/WBES/New_Comprehensive_May_5_2025.dta`. The variables used are listed in [`Section_4.3/README.md`](Section_4.3/README.md), §4.3. If that release has been superseded, request it from the Enterprise Surveys team at `enterprisesurveys@worldbank.org`.
- **Access date:** May 2025.
- **Citation:** World Bank. (2025). *Enterprise Surveys: Combined global raw dataset, 2006–2025* (release 5 May 2025) [Data set]. https://www.enterprisesurveys.org
- **License:** Free after registration. Under the Enterprise Surveys terms of use, the microdata may not be redistributed or shared with third parties.
- **Access type:** Accessible (free download after registration; redistribution not permitted).
- **License URL:** Enterprise Surveys Data Access Protocol, accepted at registration on https://www.enterprisesurveys.org

### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.
- [x] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permissions are documented in the [LICENSE](LICENSE) file.
