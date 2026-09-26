# Replication package — firm-level application

**News-Based Multidimensional Political Instability in West and Central Africa**
Philipp Kronenberg (KOF, ETH Zurich) · Kabinet Kaba (World Bank) · Pierre Mandon (World Bank, corresponding author)

This package reproduces the microeconomic application of the paper — Tables 3 to 7, which link the
news-based political instability sentiment (NBS) indicators to firm performance in the World Bank
Enterprise Surveys. The macroeconomic application (the VAR evidence for the Democratic Republic of
the Congo) is produced by a separate codebase and is not covered here.

Everything runs from a single file: **`NBS_Master.do`**.

---

## 1. Software

| Requirement | Detail |
|---|---|
| Stata | 17 or later (`version 17` is declared in the do-file) |
| User packages | `kountry`, `outreg`, `estout` |

The tables report the sample size and the number of level-2 groups, but no pseudo-R-squared: in a
multilevel model the Snijders-Bosker measures are not comparable to an OLS R-squared and invite a
goodness-of-fit reading this design cannot support.

The packages install automatically at the top of the do-file if missing. On a firewalled machine,
install them beforehand with `ssc install <name>`.

---

## 2. Folder structure

```
<PROJECT ROOT>/
├── NBS_Master.do
├── Data/
│   ├── NBS data/NBS_indicators.xlsx   (included)
│   ├── WDI/WDI_<series>.xlsx          (included; six workbooks, see §4.2)
│   ├── WBES/New_Comprehensive_May_5_2025.dta   ← NOT included; download it yourself (§4.3)
│   └── Finale_Data/                   ← created automatically; NOT included
└── Tables/                            ← created automatically; the tables in the paper are included
```

The WBES file and `Finale_Data.dta` are listed in the repository's `.gitignore`, so a copy you
download into `Data/WBES/` will not be committed by mistake. `Data/WBES/` contains only a `.gitkeep`
placeholder in the repository.

---

## 3. How to run

**Download the WBES data first.** Place the Enterprise Surveys file in `Data/WBES/` as described in
§4.3. Without it the processing step stops at PART III.

**Set the project root.** In the `USER SETTINGS` block of section 0, point `$root` at the project
folder. This is the only path that ever needs editing; everything else is derived from it. Use
forward slashes, including on Windows.

```stata
global root "C:/Users/wb603854/OneDrive - WBG/Congo Republic/NBS Paper"
```

**Run the whole file.** On a first run, leave both switches at 1:

```stata
global run_processing 1     // build Finale_Data.dta from the three raw sources
global run_tables     1     // estimate the models and write Tables 3-7
```

Once `Finale_Data.dta` exists, set `run_processing` to 0 to re-run the estimations only. **Any
change to variable construction — including `$winsor_pct` — requires `run_processing 1`**, since
the analysis file has to be rebuilt.

**Other switches.**

| Switch | Location | Default | Effect |
|---|---|---|---|
| `$winsor_pct` | PART IV | `1` | Winsorizing percentile for real sales; `0` disables it |
| `$run_other_dims` | PART X | `0` | `1` also produces the tables for the three non-reported instability dimensions, written to `Tables/Dimension_1.doc` … `Dimension_3.doc` — the "available upon request" results |

A full run writes a plain-text log to `<PROJECT ROOT>/NBS_Master.log`.

---

## 4. Input data

Three raw sources are required. The package includes two of them, the NBS indicators and the WDI
series. **The third, the World Bank Enterprise Surveys firm-level data, cannot be redistributed and
has to be downloaded by the replicator** (§4.3). The same restriction covers `Finale_Data.dta`,
which is still firm-level microdata: each row is one surveyed firm, carrying its identifier, survey
weights and questionnaire answers. It is therefore not included, and `NBS_Master.do` rebuilds it
from the WBES file.

### 4.1 NBS indicators — `Data/NBS data/NBS_indicators.xlsx`, sheet `NBS_Indicators_`

Annual country-year panel of the indicators built in the first half of the paper from Factiva news
data. First row must contain the variable names.

| Column | Content |
|---|---|
| `date` | Year (renamed `Year` on import) |
| `country` | Country name |
| `Count_Ins`, `NBS_A_Ins`, `NBS_B_Ins` | Instability **of** the political regime |
| `Count_InsW`, `NBS_A_InsW`, `NBS_B_InsW` | Instability **within** the political regime |
| `Count_Civ`, `NBS_A_Civ`, `NBS_B_Civ` | Mass civil protest |
| `Count_Poli`, `NBS_A_Poli`, `NBS_B_Poli` | Politically motivated violence |

`NBS_A` is Index A, the paper's baseline (referred to simply as NBS); `NBS_B` is Index B; `Count`
is the raw article count. The two alternatives appear in Table 4 as NBS-B and NBS-Count.

Two requirements matter for replication. The indices used elsewhere in the paper are **monthly**
and must be aggregated to annual frequency before this file is produced, because the Enterprise
Surveys are annual. And coverage must extend far enough back to support the three-year lags: the
code builds the lags on the full series before applying any year restriction, precisely so that the
earliest survey waves keep their lagged values.

*Access:* included. The underlying Dow Jones Factiva articles are licence-restricted, but this
file holds only the aggregated country-year indicators, which the main replication package also
publishes (`Data/Derived/annual/NBS_indicators.csv`).

### 4.2 World Development Indicators — `Data/WDI/WDI_<series>.xlsx`, sheet `Sheet1`

Six workbooks, one per series: `GDP_growth1`, `GDP1`, `GDPper1`, `GDPper_growth1`,
`Exchange_Rate1`, `GDP_Deflator1`. Each in **wide** layout with the first row as variable names:

- one country-name column — the header may be `Country`, `CountryName`, `country`, `Economy` or a
  similar variant; the import routine detects it and standardises the name;
- one column per year, named `x1960` through `x2024`.

The exchange rate and the GDP deflator convert firm turnover into constant-price US dollars; the
GDP series enter as country-level controls at the *t*−1 and *t*−3 lags.

*Access:* public, from the World Bank WDI portal. Included.

### 4.3 World Bank Enterprise Surveys — `Data/WBES/New_Comprehensive_May_5_2025.dta`

The harmonized global WBES panel, 2006–2024 waves.

| Group | Variables |
|---|---|
| Identifiers, survey design | `country` (the survey id, e.g. `Nigeria2014`, from which `Year` and `Country` are parsed), `idstd`, `wt_rs`, `strata_all` |
| Classification | `isic_v4`, `sector_MS`, `size`, `a3ax` |
| Outcomes | `d2` (annual sales), `n3` (sales three years ago), `l1`, `l2` (employment now and three years ago) |
| Controls | `b1`, `b2a`, `b2b`, `b2c`, `b5`, `b7a`, `c7`, `c8`, `c10`, `d12b`, `k8` |
| Recoded for missing values | a further 70-odd questionnaire items, listed in PART IV |

*Access:* **not included.** Free registration at `enterprisesurveys.org`; micro-data are not
redistributable.

### 4.4 Treatment of sales

Turnover is reported in local currency. It is converted to US dollars at the period exchange rate
and deflated by the **rebased** GDP deflator (`GDP_Deflator1 / 100`, since the series is an index
with base 100), giving constant-price dollars. Real sales are then **winsorized at the 1st and 99th
percentiles within country**, before growth rates, logarithms and standardized series are derived
from them. Winsorizing within rather than across countries preserves the cross-country size
differences that the country fixed effects absorb — a very large firm is plausible in Nigeria and
not in Guinea-Bissau.

Winsorizing removes implausible extremes but does **not** materially reduce the dispersion of log
sales, whose standard deviation stays at 2.9 — a factor of eighteen in turnover. That dispersion is
a genuine feature of a sample pooling micro-enterprises with large firms; §7 explains why it
matters for interpretation.

### 4.5 Sample coverage

The regional panel has 17 countries. The Enterprise Surveys cover 16 — there are no usable data for
Equatorial Guinea — giving 18,080 firm-level observations in the descriptive sample. Item
non-response and the exchange-rate requirement reduce the estimation samples further, to 15
countries in Tables 4, 5 and the ownership columns, and 14 in the sectoral splits. The do-file
prints the actual number of level-2 groups for each model, and `outreg` reports that count rather
than assuming a figure.

---

## 5. Outputs

All output is written to `Tables/`. Each table gets its own file, in Word format for circulation
and as a LaTeX fragment for the manuscript.

| Table | Outcome | Word | LaTeX |
|---|---|---|---|
| 3 — Descriptive statistics | — | `Table3_Descriptive_Statistics.rtf` | `Table3_firm.tex`, `Table3_country.tex` |
| 4 — Baseline | growth and levels | `Table4_Firm_Performance.doc` | `Table4_Firm_Performance.tex` |
| 5 — By firm size | growth and levels | `Table5_By_Firm_Size.doc` | `Table5_By_Firm_Size.tex` |
| 6 — By ownership and sector | growth | `Table6_By_Ownership_Sector.doc` | `Table6_By_Ownership_Sector.tex` |
| 7 — By ownership and sector | levels | `Table7_By_Ownership_Sector_Sales.doc` | `Table7_By_Ownership_Sector_Sales.tex` |

The LaTeX fragments are `booktabs` tabulars carrying the coefficient of interest only, matching how
the paper reports results. Coefficient labels are plain text rather than math mode, because an
unescaped `$` in a Stata string triggers macro expansion.

---

## 6. Pipeline and specification

| Part | What it does |
|---|---|
| I | NBS indicators: import, build the *t*−1 to *t*−3 lags, attach ISO3 codes |
| II | WDI: import six workbooks, harmonise country names to ISO3, assemble `WDI_Database.dta` |
| III | WBES: import, parse `Year` and `Country` from the survey id, merge macro and NBS data on `iso3c`–`Year` |
| IV | Recode missing values, remove outliers, convert and winsorize sales, build outcomes and controls, standardize, save `Finale_Data.dta` |
| V–IX | Tables 3 to 7 |
| X | The three non-reported instability dimensions (disabled by default) |

All models are multilevel mixed-effects regressions (`xtmixed`, maximum likelihood) with a country
random intercept, country and year fixed effects, and standard errors clustered at the country
level. The design follows Kouamé and Tapsoba (2019, *World Development*), who study firm-level
outcomes with country-level treatment variables in the same WBES setting.

---

## 7. What the design can and cannot deliver

This is not a bug and cannot be fixed by cleaning the data. It is a property of the design, and the
paper states it explicitly.

The instability indicator varies only at the country×year level, and the surveys supply roughly
thirty country-year cells. Country and year fixed effects absorb some twenty-five of the
corresponding dimensions, leaving a handful of residual degrees of freedom to identify the
coefficient. Two consequences follow.

**Growth outcomes are well behaved.** Taking growth rates differences out the permanent component
of firm heterogeneity, so the dependent variable is comparable across the sample. The growth
estimates are correspondingly stable: successive changes in how real sales are built — winsorizing,
converting to dollars, rebasing the deflator — moved the baseline growth coefficient only from
−0.24 to −0.28.

**Level outcomes are not.** The same changes moved the baseline level coefficient from −0.04 to
−1.08. And the level estimates are near-identical across every split: small, medium and large
firms, domestic firms, manufacturing and services all land between −0.99 and −1.12, a standard
deviation of 0.04 across seven estimates, against 0.18 for the corresponding growth coefficients. A
heterogeneity analysis whose estimates do not vary across subsamples is not detecting
group-specific responses; it is reproducing the same thinly identified country-year variation in
each cell.

The paper therefore bases its firm-level claims on the growth specifications and reports the level
specifications for completeness, interpreting their sign but not their magnitude. Replicating the
exercise on a panel with denser country-year coverage is the natural extension.

---


## 8. Contact

Pierre Mandon — `pmandon@worldbank.org`
