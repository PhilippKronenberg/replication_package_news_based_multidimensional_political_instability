*==============================================================================*
*  NBS PAPER - Kronenberg, Kaba & Mandon                                       *
*  "News-Based Multidimensional Political Instability in West and Central       *
*   Africa"                                                                    *
*                                                                              *
*  MASTER DO-FILE: data processing + estimation (micro / WBES application)     *
*  Consolidates: Processing_data.do  +  Estimates.do                           *
*                                                                              *
*  Produces: Table 3 (Descriptive Statistics)                                  *
*            Table 4 (Firms' Performance and Political Violence)               *
*            Table 5 (... Heterogeneity by Firm Size)                          *
*            Table 6 (... Heterogeneity by Ownership and Sector)               *
*==============================================================================*

/*------------------------------------------------------------------------------
  CHANGES MADE WHEN CONSOLIDATING (please review)
  ------------------------------------------------------------------------------
  [C1] All hard-coded absolute paths replaced by a single $root global. Set it
       once in the USER SETTINGS block below.
  [C2] Output file globals were never defined in Estimates.do: the code wrote
       "$Estimates.doc" and "$Estimates_Output.doc" (two different, undefined
       macros), so every table was silently written to a file literally named
       ".doc". Output targets are now defined explicitly, one per table
       (see [C8]).
  [C3] Redundant `local a ...` immediately followed by `foreach a in ...`
       removed throughout (the local was never used).
  [C4] `xi:` prefix dropped: factor-variable notation (i.var) is native since
       Stata 11 and `xi:` is not needed.
  [C5] Table 3 (descriptive statistics) code did not exist. Added in PART V.
  [C6] Part II of Processing_data.do merged onto a hard-coded working copy
       ("WDI_GDP_growth1 - Copy.dta") that had to be created by hand. Replaced
       by an explicit, reproducible merge loop.
  [C7] Added a bug-fix log (see FLAGS below), dependency check, and logging.

  FLAGS - ISSUES FOUND THAT AFFECT REPORTED NUMBERS (decision needed)
  ------------------------------------------------------------------------------
  [F1] RESOLVED. In Estimates.do, Table 5 columns 4-6 (sales levels) were
       estimated with `l1NBS_A_1' = NBS Index A, dimension 1 = INSTABILITY OF
       THE REGIME, whereas columns 1-3 and the whole of Tables 4 and 6 use
       `..._4' = POLITICAL VIOLENCE. The table therefore mixed two different
       instability dimensions while the paper described it entirely as political
       violence. All six columns now use l1NBS_A_4 / l3NBS_A_4. The sales-level
       coefficients in columns 4-6 will differ from every earlier draft.
  [F2] RESOLVED. Estimates.do split ownership at `b2a>=50' / `b2b>=50' while
       the domestic/foreign dummies were built at `>=51', so a firm held exactly
       50/50 entered BOTH the domestic and the foreign column. Table 6 now
       splits on the dummies themselves (majority ownership, >= 51 percent).
       Sample sizes differ slightly from earlier drafts.
  [F3] RESOLVED. Estimates.do ended with a second, near-identical block that
       re-ran the Table 4 specifications on dimension _1 under the title
       "Table 4". It is subsumed into the PART X loop over the three
       non-reported dimensions, disabled by default ($run_other_dims).
  [F4] RESOLVED. `Labor_3_Years' (= l2, employment three years ago) entered
       $controls in levels while every other control was standardized. It is now
       standardized with the rest. Rescaling a control is a linear
       transformation, so the NBS coefficients are unaffected.
  [F5] RESOLVED, and it had a consequence nobody had traced. The NBS series was
       truncated at 2005 BEFORE the lags were generated, so a 2006 survey wave
       could not reach back three years and lost its lagged NBS values entirely.
       Guinea-Bissau, whose only Enterprise Survey wave is 2006, therefore
       vanished from every estimation sample - which is why the models returned
       15 countries while the descriptive sample has 16. The lags are now built
       on the full series and the year restriction is applied afterwards.
       Guinea-Bissau should reappear and every N will rise.

  [F6] RESOLVED - but note what changed, because it affects every standard error
       reported before this version. Earlier drafts estimated every model with
       `cluster(country)' and `|| country:'. `country' is the WBES survey
       identifier, which concatenates country and year ("Nigeria2014") - which is
       precisely why Year and Country are recovered from it by substr() in
       PART III. The random intercept and the clustering therefore sat at the
       country x survey-wave level: e(N_g) returned 32 groups for 16 countries,
       and the standard errors were clustered on 32 cells rather than 16. That is
       less conservative than country clustering, so the t-statistics in earlier
       drafts were overstated. It also explains why "# Countries", "16" had to be
       hard-coded in every outreg addrows() call: the model never saw 16 groups.
       Note that the country FIXED effects were never affected - had they been at
       country x wave level, the NBS regressor (which varies at exactly that
       level) would have been collinear with them and dropped.
       Both the random intercept and the clustering now use CountryID, the
       numeric recoding of iso3c built at the top of the TABLES section. iso3c is
       the key both merges ran on, so it carries exactly one value per country.
       Numeric_Country is deliberately NOT used: it is derived from a substr() of
       the survey string and is not guaranteed to be clean.

  [F7] RESOLVED. The sales-level columns used `stdoutput', the standardized
       LEVEL of real sales, while Table 3 of the paper described "Sales" in logs
       (mean 12.2, min 2.4, max 25.9). The level is extremely right-skewed, which
       is the likely reason those coefficients came out an order of magnitude
       smaller than the growth ones. The specifications now use stdlogoutput,
       the standardized log of real sales, so the table and the regressions
       measure the same object. The sales-level coefficients will change.

  [F11] RESOLVED - newly identified, and the likely source of the implausible
       sales-level magnitudes. `d2_Dollar_Deflated' was computed as
       d2 / GDP_Deflator1: the local-currency value was deflated but never
       converted to dollars, although the variable name and the manuscript both
       say otherwise. Real sales therefore mixed CFA francs, naira, cedis and
       dalasis in a single variable, which is what pushed sd(log sales) to 2.9.
       Sales growth was never affected, being a ratio of two same-currency
       values - which is why the growth estimates were plausible throughout while
       the level ones were not. The conversion now divides by the exchange rate
       and then by the deflator rebased to its base of 100, giving constant-price
       US dollars. Note that neither fix reduces sd(log sales), which stays at
       2.9: that dispersion is genuine in a sample pooling micro-enterprises with
       large firms, and no further cleaning will change it.

  [F9] RESOLVED. The sales-level specifications regressed a logged outcome on the
       untransformed level of lagged sales, mixing scales. The growth
       specifications keep the level control (output_T_3); the level
       specifications now use its log (logoutput_T_3).

  [F10] RESOLVED - newly identified. Real sales still ranged from roughly USD 11
       to USD 177 billion a year after the outlier filter, which cuts at 3 sd of
       the log within country x sector and is far too permissive with tails this
       fat. Because every coefficient is expressed in standard deviations of the
       outcome, and sd(log sales) was 3.0, those few implausible values turned
       moderate estimates into economically absurd ones: the baseline sales-level
       coefficient implied an 88 percent fall in sales for a one-standard-
       deviation rise in violence. Sales are now winsorized at the 1st and 99th
       percentiles within country, before growth, the logs and the
       standardization are derived from them ($winsor_pct controls the cut, 0
       disables it). The sales-level coefficients should fall substantially.

  [F8] RESOLVED - newly identified. The lag variables did not mean what their
       names said. The original code chained lags of lags
       (l`a' = l.`a', l1`a' = l.l`a', ...), so the variable called l1 was in fact
       t-2 and the one called l3 was t-4, while the manuscript described them as
       t-1 and t-3. They are now generated as L1., L2. and L3. of the series.
       This shifts the instability window used in every firm-level table.
------------------------------------------------------------------------------*/


/*==============================================================================
  REQUIRED INPUT DATA
  ==============================================================================
  Three raw sources are needed. Paths are relative to $root, set below.

  (1) $root/Data/NBS data/NBS_indicators.xlsx        [sheet: "NBS_Indicators_"]
      ANNUAL country-year NBS indicators, first row = variable names. Must
      contain: date (the year; renamed Year), country, and the twelve series
          Count_Ins   NBS_A_Ins   NBS_B_Ins      (instability OF the regime)
          Count_InsW  NBS_A_InsW  NBS_B_InsW     (instability WITHIN the regime)
          Count_Civ   NBS_A_Civ   NBS_B_Civ      (mass civil protest)
          Count_Poli  NBS_A_Poli  NBS_B_Poli     (political violence)
      NBS_A = Index A (baseline), NBS_B = Index B, Count = raw article counts.
      Coverage must start in 2005 at the latest: earlier observations are
      dropped, and the t-3 lags matched to the 2008+ WBES waves are built from
      2005 onward. The monthly indices behind the paper's figures must therefore
      be aggregated to annual frequency BEFORE this file is produced.

  (2) $root/Data/WDI/WDI_<series>.xlsx                     [sheet: "Sheet1"]
      Six World Development Indicators workbooks, one per series:
          WDI_GDP_growth1     WDI_GDP1            WDI_GDPper1
          WDI_GDPper_growth1  WDI_Exchange_Rate1  WDI_GDP_Deflator1
      WIDE layout, first row = variable names: one country-name column (any of
      Country / CountryName / country / Economy - it is auto-detected) plus one
      column per year named x1960 ... x2024.

  (3) $root/Data/WBES/New_Comprehensive_May_5_2025.dta
      World Bank Enterprise Surveys, harmonized global panel (2006-2024 waves).
      Variables used:
        - identifiers and survey design: country (the survey id, e.g.
          "Nigeria2014", from which Year and Country are parsed), idstd,
          wt_rs, strata_all
        - classification: isic_v4, sector_MS, size, a3ax
        - questionnaire items: d2 (annual sales), n3 (sales three years ago),
          l1 (employment), l2 (employment three years ago), b1, b2a, b2b, b2c,
          b5, b7a, c7, c8, c10, d12b, k8, plus the further items recoded from
          negative "don't know / refused" codes in PART IV.

  Stata packages (installed automatically if missing): kountry, outreg, estout.

  OUTPUTS - written to $root/Tables, one file per table:
      Table3_Descriptive_Statistics.rtf  + Table3_firm.tex, Table3_country.tex
      Table4_Firm_Performance.doc        + Table4_Firm_Performance.tex
      Table5_By_Firm_Size.doc            + Table5_By_Firm_Size.tex
      Table6_By_Ownership_Sector.doc     + Table6_By_Ownership_Sector.tex
      Table7_By_Ownership_Sector_Sales.doc  + ..._Sales.tex
  plus the working file $root/Data/Finale_Data/Finale_Data.dta and the run log
  $root/NBS_Master.log.
==============================================================================*/


*==============================================================================*
*  0. SET-UP                                                                   *
*==============================================================================*

clear all
set more off
set varabbrev off
version 17

*--- USER SETTINGS: set $root to the project folder, everything else follows ---*
global root "C:/Users/wb603854/OneDrive - WBG/Congo Republic/NBS Paper"

global nbs      "$root/Data/NBS data"
global wdi      "$root/Data/WDI"
global wbes     "$root/Data/WBES"
global final    "$root/Data/Finale_Data"
global tables   "$root/Tables"

cap mkdir "$final"
cap mkdir "$tables"

*--- Output targets: one file per table, all in $tables -------------------------*
* [C8] In the original code every table was written to the same destination with
* `replace' on its first column, so Table 5 overwrote Table 4 and Table 6
* overwrote Table 5: only the last table survived a full run. Each table now has
* its own file. Word (.doc/.rtf) is produced for circulation and a LaTeX
* fragment for the manuscript.
global t3_doc "$tables/Table3_Descriptive_Statistics"
global t4_doc "$tables/Table4_Firm_Performance"
global t5_doc "$tables/Table5_By_Firm_Size"
global t6_doc "$tables/Table6_By_Ownership_Sector"
global t7_doc "$tables/Table7_By_Ownership_Sector_Sales"
global tables_tex "$tables"                     // esttab LaTeX fragments

*--- Presentation settings shared by Tables 4-6 ---------------------------------*
global starlev  10 5 1
global texnote  "Robust standard errors, clustered at the country level, in parentheses. All variables are standardized; coefficients are in standard deviation units. Only the coefficient of interest is reported: every specification also includes the full set of firm- and country-level controls and country and year fixed effects."

*--- Dependencies --------------------------------------------------------------*
foreach pkg in kountry outreg estout {
    cap which `pkg'
    if _rc ssc install `pkg', replace
}

*--- Log -----------------------------------------------------------------------*
cap log close
log using "$root/NBS_Master.log", replace text

*--- Run switches: set to 0 to skip a block ------------------------------------*
global run_processing 1
global run_tables     1

*--- Level of the random intercept and of the clustering -----------------------*
* Both are set at the COUNTRY level, built from iso3c (see PART V). Earlier
* versions used the WBES variable `country', which is the survey identifier
* ("Nigeria2014") and therefore country x wave: that produced 32 level-2 groups
* instead of 16 and understated the standard errors. Resolved; no switch left.


if $run_processing {

*==============================================================================*
*  PART I. NBS INDICATORS                                                      *
*==============================================================================*

clear all
import excel "$nbs/NBS_indicators.xlsx", sheet("NBS_Indicators_") firstrow
rename date    Year
rename country Country

egen countrynum = group(Country)
xtset countrynum Year, yearly

* Dimension suffixes: Ins = instability OF regime      -> _1
*                     InsW = instability WITHIN regime -> _2
*                     Civ  = mass civil protest        -> _3
*                     Poli = political violence        -> _4
*
* [F8] The lag names now mean what they say: l1 = t-1, l2 = t-2, l3 = t-3.
* The original code chained lags of lags (l1X = l.lX), so the variable called
* l1 was in fact t-2 and the one called l3 was t-4, while the manuscript
* described them as t-1 and t-3.
*
* [F5] The lags are built BEFORE any year is dropped. The original code cut the
* series at 2005 first, so a 2006 survey wave could not reach back three years
* and lost its lagged NBS values. Guinea-Bissau, whose only wave is 2006, was
* therefore dropped from every estimation sample - which is why the models
* returned 15 countries instead of 16.
foreach a in Count_Ins NBS_A_Ins NBS_B_Ins       ///
             Count_InsW NBS_A_InsW NBS_B_InsW    ///
             Count_Civ NBS_A_Civ NBS_B_Civ       ///
             Count_Poli NBS_A_Poli NBS_B_Poli {
    gen l1`a' = L1.`a'
    gen l2`a' = L2.`a'
    gen l3`a' = L3.`a'
}

drop if Year < 2005                              // now harmless: lags already built

drop countrynum

kountry Country, from(other) stuck
rename _ISO3N_ code_iso3n
kountry code_iso3n, from(iso3n) to(iso3c)
tab Country if _ISO3C_ == ""
drop if _ISO3C_ == ""
rename _ISO3C_ iso3c

save "$nbs/NBS_Data.dta", replace


*==============================================================================*
*  PART II. WDI MACRO DATA                                                     *
*==============================================================================*

*--- II.a Import and clean each WDI series ------------------------------------*
foreach y in GDP_growth1 GDP1 GDPper1 GDPper_growth1 Exchange_Rate1 GDP_Deflator1 {

    clear all
    import excel "$wdi/WDI_`y'.xlsx", sheet("Sheet1") firstrow
    gen id = _n
    reshape long x, i(id) j(Year)
    rename x `y'
    destring `y', replace

    *--- Harmonize the country-name variable -----------------------------------*
    * The WDI workbooks do not all carry the same header for the country column
    * ("Country", "Country Name" -> CountryName, "Economy", lowercase "country",
    * ...). `import excel, firstrow` keeps whatever the header says, so the name
    * is detected here and standardized to Country before it is used below.
    * This is what raised "Country not found" / r(111) in the original code.
    capture confirm variable Country
    if _rc {
        local cvar ""
        foreach cand in CountryName Countryname countryname CountryName_        ///
                        Country_Name CountryNam country COUNTRY Economy         ///
                        EconomyName Economyname Pays NomPays {
            capture confirm variable `cand'
            if !_rc & "`cvar'" == "" local cvar "`cand'"
        }
        * Fallback: first string variable that is not an ISO / numeric code
        if "`cvar'" == "" {
            quietly ds, has(type string)
            foreach v in `r(varlist)' {
                if "`cvar'" == "" & !inlist("`v'", "iso3c", "iso2c", "iso3n",   ///
                    "CountryCode", "Countrycode", "countrycode", "code",        ///
                    "SeriesName", "SeriesCode") local cvar "`v'"
            }
        }
        if "`cvar'" == "" {
            display as error ///
                "No country-name variable found in WDI_`y'.xlsx - variables are:"
            describe, simple
            exit 111
        }
        rename `cvar' Country
        display as text "  [info] WDI_`y'.xlsx: renamed `cvar' -> Country"
    }

    * Guard against a numeric country column (e.g. codes imported as numbers)
    capture confirm string variable Country
    if _rc {
        display as error "WDI_`y'.xlsx: Country is numeric, expected country names."
        exit 109
    }

    drop if missing(Country)

    kountry Country, from(other) stuck
    rename _ISO3N_ code_iso3n
    kountry code_iso3n, from(iso3n) to(iso3c)
    rename _ISO3C_ iso3c

    * Manual ISO fixes for names kountry cannot resolve
    replace iso3c = "CPV" if Country == "Cabo Verde"
    replace iso3c = "CZE" if Country == "Czechia"
    replace iso3c = "EGY" if inlist(Country, "Egypt, Arab Republic of")
    replace iso3c = "SWZ" if inlist(Country, "Eswatini", "Eswatini, Kingdom of")
    replace iso3c = "XKX" if Country == "Kosovo"
    replace iso3c = "MKD" if Country == "North Macedonia"
    replace iso3c = "SOM" if Country == "Somalia, Fed. Rep."
    replace iso3c = "VEN" if Country == "Venezuela, Republica Bolivariana de"
    replace iso3c = "YEM" if Country == "Yemen, Republic of"
    replace iso3c = "TUR" if Country == "Turkiye"
    replace iso3c = "SXM" if Country == "St Maarten"
    replace iso3c = "CUW" if Country == "Curacao"
    replace iso3c = "HKG" if Country == "Hong Kong SAR, China"
    replace iso3c = "MAC" if Country == "Macao SAR, China"
    replace iso3c = "PRI" if Country == "Puerto Rico (US)"
    replace iso3c = "MAF" if Country == "St. Martin (French part)"
    replace iso3c = "COM" if Country == "Comoros, Union of the"
    replace iso3c = "CIV" if Country == "Côte d'Ivoire"
    replace iso3c = "GNQ" if Country == "Equatorial Guinea, Republic of"
    replace iso3c = "ERI" if Country == "Eritrea, The State of"
    replace iso3c = "ETH" if Country == "Ethiopia, The Federal Democratic Republic of"
    replace iso3c = "LSO" if Country == "Lesotho, Kingdom of"
    replace iso3c = "MDG" if Country == "Madagascar, Republic of"
    replace iso3c = "MRT" if Country == "Mauritania, Islamic Republic of"
    replace iso3c = "MOZ" if Country == "Mozambique, Republic of"
    replace iso3c = "STP" if Country == "São Tomé and Príncipe, Democratic Republic of"

    tab Country if iso3c == ""
    drop if iso3c == ""

    keep iso3c Country Year `y'
    save "$wdi/WDI_`y'.dta", replace
}

*--- II.b Assemble the WDI database (see [C6]) --------------------------------*
clear all
use "$wdi/WDI_GDP_growth1.dta"
foreach y in GDP1 GDPper1 GDPper_growth1 Exchange_Rate1 GDP_Deflator1 {
    merge m:1 iso3c Year using "$wdi/WDI_`y'.dta", ///
          keepusing(`y') keep(matched) nogen
}

egen countrynum = group(iso3c)
xtset countrynum Year, yearly
foreach a in GDP_growth1 GDP1 GDPper1 GDPper_growth1 {
    gen l1`a' = l.`a'
    gen l2`a' = l.l1`a'
    gen l3`a' = l.l2`a'
}
drop countrynum

save "$wdi/WDI_Database.dta", replace


*==============================================================================*
*  PART III. WBES FIRM-LEVEL DATA AND MERGE                                    *
*==============================================================================*

clear all
use "$wbes/New_Comprehensive_May_5_2025.dta"

gen Year    = substr(country, -4, 4)
destring Year, replace
gen Country = substr(country, 1, strlen(country) - 4)

replace Country = "Antigua and barbuda"          if Country == "Antiguaandbarbuda"
replace Country = "Burkina Faso"                 if Country == "BurkinaFaso"
replace Country = "Cape Verde"                   if Country == "Cabo Verde"
replace Country = "Central african republic"     if Country == "Centralafricanrepublic"
replace Country = "Cote d'Ivoire"                if Country == "Côte d'Ivoire"
replace Country = "Democratic republic of congo" if Country == "DRC"
replace Country = "Dominican Republic"           if Country == "DominicanRepublic"
replace Country = "El Salvador"                  if Country == "ElSalvador"
replace Country = "Swaziland"                    if Country == "Eswatini"
replace Country = "Lao PDR"                      if Country == "LaoPDR"
replace Country = "Papua New Guinea"             if Country == "PapuaNewGuinea"
replace Country = "Sierra Leone"                 if Country == "SierraLeone"
replace Country = "South Africa"                 if Country == "SouthAfrica"
replace Country = "South sudan"                  if Country == "Southsudan"
replace Country = "Sri Lanka"                    if Country == "SriLanka"
replace Country = "St Kitts and Nevis"           if Country == "StKittsandNevis"
replace Country = "St Lucia"                     if Country == "StLucia"
replace Country = "St Vincent and Grenadines"    if Country == "StVincentandGrenadines"
replace Country = "Trinidad and Tobago"          if Country == "TrinidadandTobago"
replace Country = "Turkey"                       if Country == "Turkiye"
replace Country = "Hong Kong"                    if Country == "Hong Kong SAR China"
replace Country = "Taiwan"                       if Country == "Taiwan China"
replace Country = "Macedonia"                    if Country == "North Macedonia"
replace Country = "Korea"                        if Country == "Korea Republic"

kountry Country, from(other) stuck
rename _ISO3N_ iso3n_
kountry iso3n_, from(iso3n) to(iso3c)
replace _ISO3C_ = "CZE" if Country == "Czechia"
tab Country if _ISO3C_ == ""
drop if _ISO3C_ == ""
rename _ISO3C_ iso3c
order Country Year country iso3c

kountry iso3c, from(iso3c) geo(sov)
rename GEO Region

drop if Year == 2025

*--- Merge macro and NBS data; the NBS merge restricts the sample to the -------*
*--- regional panel. Equatorial Guinea drops out for lack of usable WBES -------*
*--- data, leaving 16 of the 17 sample countries (see paper, Section 4.3.1). ---*
merge m:1 iso3c Year using "$wdi/WDI_Database.dta",  keep(matched) nogen
merge m:1 iso3c Year using "$nbs/NBS_Data.dta",      keep(matched) nogen

tab Country, missing                              // expect 16 countries


*==============================================================================*
*  PART IV. VARIABLE CONSTRUCTION                                              *
*==============================================================================*

*--- Survey design -------------------------------------------------------------*
svyset idstd [pw=wt_rs], strata(strata_all) singleunit(scaled)

*--- Recode "don't know / refused" negative codes as missing -------------------*
foreach c in d2 n3 b5 l1 l2 l3a l3b l4a l4b l5 l5a l5b l6 l6a l14a l14b   ///
             c7 c8 d3a d3b d3c b7a c9a c9b c10 k3bc k3a k3b k3c k3e      ///
             b2b b2a b2c b2d d6 d7 d10 d10a d11 d12a d12b e6 e11 f1      ///
             h1 h2 h5 h8 i1 i2a i4a j6 n2a n2b n2c n2d n2e n2f n2g n2h   ///
             n4b n5a n5b n6a n6b d30b d30a j30f l30a j7a j30e j30a i30   ///
             k8 k6 k11 k7 k15a k15b k30 c30a c6 b1 {
    replace `c' = . if `c' < 0
}

*--- Aggregate sectors ---------------------------------------------------------*
gen str20 Sector = ""
replace Sector = "Water & Electricity" if isic_v4 >= 35 & isic_v4 <= 39
replace Sector = "Manufacturing"       if isic_v4 >= 10 & isic_v4 <= 33
replace Sector = "Service"             if isic_v4 >= 41

*--- Flag and remove outliers (>3 sd from country x sector mean, in logs) ------*
foreach var of varlist d2 n2e n3 l1 l2 b2a b2b b2c d3b d3c {
    generate `var'o_sec = 0
    generate log`var'   = log(`var' + 1)
    egen `var'mean = mean(log`var'), by(country sector_MS)
    egen `var'sd   = sd(log`var'),   by(country sector_MS)
    replace `var'o_sec = 1 if log`var' > `var'mean + 3*`var'sd & `var' != . & log`var' != .
    replace `var'o_sec = 2 if log`var' < `var'mean - 3*`var'sd & `var' != .
    drop `var'mean `var'sd
}
foreach x in d2 n2e n3 l1 l2 b2a b2b b2c d3b d3c {
    replace `x' = . if `x'o_sec != 0
}

*--- Convert local-currency values to USD and deflate --------------------------*
* [F11] The deflated series must be converted to USD as well. The original line
* read `gen `d'_Dollar_Deflated = `d' / GDP_Deflator1', i.e. it deflated the
* LOCAL CURRENCY value and never divided by the exchange rate, despite the name
* and despite the paper stating that turnover is "converted into U.S. dollars and
* deflated using the GDP deflator". Pooling CFA francs, naira and cedis into one
* variable is what made sd(log sales) 2.9 and turned moderate standardized
* coefficients into absurd percentages. Note that the growth variable was never
* affected: it is a ratio of two same-currency values, so the units cancel -
* which is exactly why the growth estimates looked sane while the level ones did
* not.
foreach d in d2 n3 n2a n2b n2c n2e n2f n2g n2h n4a n4b n5a n5b n6a n6b n2d i2b {
    gen `d'_Dollar           = `d' / Exchange_Rate1
    gen `d'_Dollar_Deflated  = (`d' / Exchange_Rate1) / (GDP_Deflator1 / 100)
}

*--- [F10] Winsorize real sales before anything is derived from them -----------*
* The outlier filter above flags values more than 3 sd from the country x sector
* mean of the log, which is a very wide net when the tails are this fat: real
* sales still ranged from about USD 11 to USD 177 billion a year, and those
* extremes are data errors rather than firms. Because sd(log sales) enters every
* standardized coefficient, they inflated the sales-level estimates.
*
* Winsorizing is done WITHIN COUNTRY, so that the cross-country distribution the
* country fixed effects rely on is preserved: a very large firm in Nigeria is
* plausible, the same figure in Guinea-Bissau is not. It is applied here, before
* growth, the logs and the standardization are computed, so that every object
* derived from sales uses the same cleaned series.

global winsor_pct 1        // set to 0 to disable winsorizing entirely

if $winsor_pct > 0 {
    local plo = $winsor_pct
    local phi = 100 - $winsor_pct
    foreach v in d2_Dollar_Deflated n3_Dollar_Deflated {
        quietly count if !missing(`v')
        local n0 = r(N)
        quietly summarize `v', detail
        local sd0 = r(sd)
        tempvar lo hi
        egen `lo' = pctile(`v'), by(iso3c) p(`plo')
        egen `hi' = pctile(`v'), by(iso3c) p(`phi')
        quietly count if (`v' < `lo' | `v' > `hi') & !missing(`v')
        local nw = r(N)
        quietly replace `v' = `lo' if `v' < `lo' & !missing(`v')
        quietly replace `v' = `hi' if `v' > `hi' & !missing(`v')
        drop `lo' `hi'
        quietly summarize `v'
        display as text "winsorized `v' at `plo'/`phi' within country: " ///
            `nw' " of " `n0' " values adjusted; sd " %9.0fc `sd0' " -> " %9.0fc r(sd)
    }
}

*--- Outcomes: growth between t and t-3, annualized, in percent ----------------*
gen output_growth = ((d2_Dollar_Deflated - n3_Dollar_Deflated) /             ///
                    ((d2_Dollar_Deflated + n3_Dollar_Deflated)/2) / 2) * 100
gen employ_growth = ((l1 - l2) / ((l1 + l2)/2) / 2) * 100

*--- Firm characteristics ------------------------------------------------------*
gen small  = (l2 <= 19)  if l2 >= 0   & l2 != .
gen medium = (l2 >= 20 & l2 <= 99)    if l2 >= 0 & l2 != .
gen large  = (l2 >= 100)              if l2 >= 0 & l2 != .

gen age    = Year - b5
gen young  = (age <  6)               if age != .
gen mature = (age >  5 & age < 16)    if age != .
gen older  = (age > 15)               if age != .

gen foreign  = (b2b >= 51) if b2b != .
gen domestic = (b2a >= 51) if b2a != .          // see [F2]

gen Credit_Line = .
replace Credit_Line = 1 if k8 == 1
replace Credit_Line = 0 if k8 == 2

gen Gender = .
replace Gender = 1 if b7a == 1
replace Gender = 0 if b7a == 2

rename b1                   Firms_Status
rename n3_Dollar_Deflated   output_3_Years
rename l2                   Labor_3_Years          // see [F4]
rename c7                   Power_Outages
rename c10                  Generator
rename d2_Dollar_Deflated   output

gen logoutput        = log(output)                 // used in Table 3 ("Sales")
gen logoutput_3_Years = log(output_3_Years)        // [F9] see below

*--- Standardize (all regression variables enter in sd units) -----------------*
* NOTE: the log variable below is `logl2', NOT `logLabor_3_Years'. The outlier
* loop above creates log`var' for each raw variable, i.e. logl2, and the later
* `rename l2 Labor_3_Years' does not propagate to derived variables. Do not
* "harmonize" this name: renaming it here raises r(111).
foreach var of varlist output logoutput output_growth l1 logl2 Labor_3_Years ///
    logoutput_3_Years                                                        ///
    l3NBS_A_Ins  l3NBS_B_Ins  l3Count_Ins   l3NBS_A_InsW l3NBS_B_InsW        ///
    l3Count_InsW l3NBS_A_Civ  l3NBS_B_Civ   l3Count_Civ  l3NBS_A_Poli        ///
    l3NBS_B_Poli l3Count_Poli l1NBS_A_Ins   l1NBS_B_Ins  l1Count_Ins         ///
    l1NBS_A_InsW l1NBS_B_InsW l1Count_InsW  l1NBS_A_Civ  l1NBS_B_Civ         ///
    l1Count_Civ  l1NBS_A_Poli l1NBS_B_Poli  l1Count_Poli                     ///
    young mature older Firms_Status Gender Credit_Line d12b c8               ///
    Power_Outages Generator small medium large                               ///
    l3GDP_growth1 l3GDP1 l3GDPper1 l3GDPper_growth1                          ///
    l1GDP_growth1 l1GDP1 l1GDPper1 l1GDPper_growth1 output_3_Years {
    egen std`var' = std(`var')
}

*--- Numeric group identifiers -------------------------------------------------*
foreach f in Country a3ax Sector {
    egen Numeric_`f' = group(`f')
}

*--- Rename standardized variables to their paper names ------------------------*
rename stdoutput_growth     Output_Growth

* [F7] The sales-level specifications now use the standardized LOG of real
* sales. Earlier drafts regressed the standardized LEVEL, which is extremely
* right-skewed, while Table 3 of the paper described "Sales" in logs. The two
* are now consistent. This changes the coefficients in the sales-level columns.
rename stdl3NBS_A_Ins       l3NBS_A_1
rename stdl3NBS_B_Ins       l3NBS_B_1
rename stdl3Count_Ins       l3NBS_Count_1
rename stdl3NBS_A_InsW      l3NBS_A_2
rename stdl3NBS_B_InsW      l3NBS_B_2
rename stdl3Count_InsW      l3NBS_Count_2
rename stdl3NBS_A_Civ       l3NBS_A_3
rename stdl3NBS_B_Civ       l3NBS_B_3
rename stdl3Count_Civ       l3NBS_Count_3
rename stdl3NBS_A_Poli      l3NBS_A_4
rename stdl3NBS_B_Poli      l3NBS_B_4
rename stdl3Count_Poli      l3NBS_Count_4
rename stdl1NBS_A_Ins       l1NBS_A_1
rename stdl1NBS_B_Ins       l1NBS_B_1
rename stdl1Count_Ins       l1NBS_Count_1
rename stdl1NBS_A_InsW      l1NBS_A_2
rename stdl1NBS_B_InsW      l1NBS_B_2
rename stdl1Count_InsW      l1NBS_Count_2
rename stdl1NBS_A_Civ       l1NBS_A_3
rename stdl1NBS_B_Civ       l1NBS_B_3
rename stdl1Count_Civ       l1NBS_Count_3
rename stdl1NBS_A_Poli      l1NBS_A_4
rename stdl1NBS_B_Poli      l1NBS_B_4
rename stdl1Count_Poli      l1NBS_Count_4
rename stdyoung             Young_Firms
rename stdmature            Mature_Firms
drop  Firms_Status
rename stdFirms_Status      Firms_Status
rename stdGender            Manager_Gender
rename stdd12b              Firm_Openess_to_Trade
rename stdGenerator         Generator_Use
rename stdCredit_Line       Credit_Access
rename stdoutput_3_Years        output_T_3
rename stdlogoutput_3_Years     logoutput_T_3
rename stdsmall             Small_Firms
rename stdmedium            Medium_Firms
rename stdl3GDP_growth1        l3GDP_growth1_T_3
rename stdl3GDP1               l3GDP1_T_3
rename stdl3GDPper1            l3GDPper1_T_3
rename stdl3GDPper_growth1     l3GDPper_growth1_T_3
rename stdl1GDP_growth1        l1GDP_growth1_T_3
rename stdl1GDP1               l1GDP1_T_3
rename stdl1GDPper1            l1GDPper1_T_3
rename stdl1GDPper_growth1     l1GDPper_growth1_T_3

* [F4] Labor_3_Years entered the control set in levels while every other control
* was standardized. The standardized version is used in the regressions; the RAW
* variable is kept under its own name because Table 3 reports it in employee
* counts, not in standard deviations. (Dropping the raw one made the
* "Employment three years ago" row of Table 3 come out as mean 0, sd 1.)
rename stdLabor_3_Years        Labor_3_Years_std

compress
save "$final/Finale_Data.dta", replace

}   // end run_processing


*==============================================================================*
*  TABLES                                                                      *
*==============================================================================*

if $run_tables {

clear all
use "$final/Finale_Data.dta"

*--- A trustworthy country identifier ------------------------------------------*
* Numeric_Country is built from Country, which is parsed out of the WBES survey
* string with substr(). If those strings are not perfectly consistent across
* waves, the identifier silently splits one country into several groups. iso3c
* is the key both merges ran on, so it is one value per country by construction.
capture drop CountryID
egen CountryID = group(iso3c)

display as text _n "=== distinct values of each candidate identifier ==="
foreach v of varlist country Country Numeric_Country iso3c CountryID {
    tempvar t
    quietly egen `t' = tag(`v')
    quietly count if `t'
    display as text %-20s "`v'" " : " r(N) " distinct values"
    drop `t'
}
display as text "(country = survey id, expect ~32; iso3c / CountryID = expect 16)" _n

*--- How much of the instability signal survives the fixed effects? ------------*
* The NBS indicator varies only at the country x year level, and the models
* already absorb country and year effects. If almost no variation is left, the
* coefficient is identified off a sliver of the data and its magnitude cannot be
* trusted. This prints the share of NBS variance explained by the fixed effects
* alone: an R-squared close to 1 is a warning, not a result.
quietly regress l1NBS_A_4 i.CountryID i.Year
display as text _n "=== identifying variation in NBS ==="
display as text "R2 of NBS(t-1) on country and year FE : " %5.3f e(r2)
display as text "residual sd as a share of total sd    : " %5.3f sqrt(1-e(r2))
quietly regress l3NBS_A_4 i.CountryID i.Year
display as text "R2 of NBS(t-3) on country and year FE : " %5.3f e(r2)
display as text "residual sd as a share of total sd    : " %5.3f sqrt(1-e(r2)) _n

*--- Global control sets -------------------------------------------------------*
* $controls  : t-3 lags, includes size dummies      -> Tables 4 (growth) and 6
* $controlls : t-1 lags, includes size dummies      -> Table 4 (sales levels)
* $controll  : t-3 lags, size dummies EXCLUDED      -> Table 5 (split by size)
* $controlll : t-1 lags, size dummies EXCLUDED      -> Table 5 (split by size)

global base_firm  Young_Firms Mature_Firms Firms_Status Manager_Gender      ///
                  Firm_Openess_to_Trade Generator_Use Credit_Access         ///
                  Labor_3_Years_std

* [F9] The baseline firm controls include past sales. The growth specifications
* use it in levels (output_T_3); the sales-level specifications, whose dependent
* variable is now the LOG of sales after [F7], use the log (logoutput_T_3).
* Regressing a logged outcome on an untransformed, extremely right-skewed level
* of the same variable was mixing scales.
global controls   $base_firm output_T_3    Small_Firms Medium_Firms         ///
                  l3GDPper1_T_3 l3GDP_growth1_T_3 l3GDP1_T_3
global controlls  $base_firm logoutput_T_3 Small_Firms Medium_Firms         ///
                  l1GDPper1_T_3 l1GDP_growth1_T_3 l1GDP1_T_3
global controll   $base_firm output_T_3                                     ///
                  l3GDPper1_T_3 l3GDP_growth1_T_3 l3GDP1_T_3
global controlll  $base_firm logoutput_T_3                                  ///
                  l1GDPper1_T_3 l1GDP_growth1_T_3 l1GDP1_T_3

global fixed_effects i.Numeric_Country i.Year

eststo clear

*--- Level-2 grouping and clustering variable ---------------------------------*
* CountryID is the numeric recoding of iso3c built above: exactly one value per
* country (16), which is what the manuscript describes. Do not substitute the
* WBES variable `country' here - it is the survey identifier (country x wave).

* Pseudo-R-squareds are deliberately not reported. In a multilevel model the
* Snijders-Bosker measures are not comparable to an OLS R-squared and invite a
* goodness-of-fit reading the design cannot support; the tables report the
* sample size and the number of level-2 groups instead.

global clvar "CountryID"                // country-level clustering (16 clusters)
global revar "CountryID"                // country-level random intercept


*==============================================================================*
*  PART V. TABLE 3 - DESCRIPTIVE STATISTICS                            [NEW]   *
*==============================================================================*
/*  NOTE ON UNITS. Table 3 of the paper reports the country-level NBS variables
    in their ORIGINAL units (e.g. political violence, t-3: mean 139.2), not in
    standard deviation units. The regressions, by contrast, use the standardized
    series (l3NBS_A_4 etc.). The code below therefore reads the RAW lagged
    series (l3NBS_A_Poli, ...), which survive the standardization step.
    "Firm status" is the one firm-level row reported standardized (mean 0,
    sd 1), matching the paper.                                                */

preserve

*--- Variable labels exactly as printed in the paper ---------------------------*
label variable logoutput             "Sales"
label variable output_growth         "Sales growth"
label variable l1                    "Full-time employment"
label variable Labor_3_Years         "Employment three years ago"
label variable young                 "Young firms"
label variable mature                "Mature firms"
label variable older                 "Older firms"
label variable Firms_Status          "Firm status"
label variable Gender                "Manager gender"
label variable d12b                  "Trade openness"
label variable Generator             "Generator use"
label variable Credit_Line           "Credit line"
label variable small                 "Small firms"
label variable medium                "Medium firms"
label variable large                 "Large firms"

label variable l3NBS_A_Ins           "NBS(t-3) (Instability of regime)"
label variable l3NBS_A_InsW          "NBS(t-3) (Instability within regime)"
label variable l3NBS_A_Civ           "NBS(t-3) (Mass civil protest)"
label variable l3NBS_A_Poli          "NBS(t-3) (Political violence)"
label variable l1NBS_A_Ins           "NBS(t-1) (Instability of regime)"
label variable l1NBS_A_InsW          "NBS(t-1) (Instability within regime)"
label variable l1NBS_A_Civ           "NBS(t-1) (Mass civil protest)"
label variable l1NBS_A_Poli          "NBS(t-1) (Political violence)"

label variable l3GDPper_growth1      "GDP per capita growth(t-3)"
label variable l3GDP_growth1         "GDP growth(t-3)"
label variable l1GDPper_growth1      "GDP per capita growth(t-1)"
label variable l1GDP_growth1         "GDP growth(t-1)"

*--- Variable blocks -----------------------------------------------------------*
global desc_firm    logoutput output_growth l1 Labor_3_Years                ///
                    young mature older Firms_Status Gender d12b             ///
                    Generator Credit_Line small medium large

global desc_country l3NBS_A_Ins l3NBS_A_InsW l3NBS_A_Civ l3NBS_A_Poli       ///
                    l1NBS_A_Ins l1NBS_A_InsW l1NBS_A_Civ l1NBS_A_Poli       ///
                    l3GDPper_growth1 l3GDP_growth1                          ///
                    l1GDPper_growth1 l1GDP_growth1

*--- On-screen check -----------------------------------------------------------*
summarize $desc_firm $desc_country, format

*--- (a) Word output, consistent with the other tables -------------------------*
* NOTE: do not add a `listwise' option here. In estpost summarize it is a flag,
* not an option taking an argument (listwise(0) raises r(198)), and the default
* - statistics computed variable by variable - is exactly what Table 3 reports:
* the number of observations differs across rows (16,352 for sales, 13,671 for
* sales growth, 17,588 for employment, ...). Specifying `listwise' would impose
* the common sample and collapse every N to the same, much smaller figure.
estpost summarize $desc_firm
esttab using "$t3_doc.rtf", replace                                   ///
    cells("count(fmt(%12.0fc)) mean(fmt(%9.1f)) sd(fmt(%9.1f)) min(fmt(%9.1f)) max(fmt(%9.1f))")                                ///
    collabels("Obs" "Mean" "Std. Dev." "Min" "Max")                         ///
    label nomtitle nonumber noobs                                           ///
    title("Table 3. Descriptive Statistics")                                ///
    addnotes("Firm-level variables.")

estpost summarize $desc_country
esttab using "$t3_doc.rtf", append                                    ///
    cells("count(fmt(%12.0fc)) mean(fmt(%9.1f)) sd(fmt(%9.1f)) min(fmt(%9.1f)) max(fmt(%9.1f))")                                ///
    collabels("Obs" "Mean" "Std. Dev." "Min" "Max")                         ///
    label nomtitle nonumber noobs                                           ///
    addnotes("Country-level variables.")

*--- (b) LaTeX fragment matching the manuscript (tab:descriptive_stats) --------*
estpost summarize $desc_firm
esttab using "$tables_tex/Table3_firm.tex", replace                       ///
    cells("count(fmt(%12.0fc)) mean(fmt(%9.1f)) sd(fmt(%9.1f)) min(fmt(%9.1f)) max(fmt(%9.1f))")                                ///
    collabels("Obs" "Mean" "Std. Dev." "Min" "Max")                         ///
    label booktabs nomtitle nonumber noobs fragment

estpost summarize $desc_country
esttab using "$tables_tex/Table3_country.tex", replace                    ///
    cells("count(fmt(%12.0fc)) mean(fmt(%9.1f)) sd(fmt(%9.1f)) min(fmt(%9.1f)) max(fmt(%9.1f))")                                ///
    collabels("Obs" "Mean" "Std. Dev." "Min" "Max")                         ///
    label booktabs nomtitle nonumber noobs fragment

*--- (c) Robustness variants (NBS-B and NBS-Count), available upon request -----*
*        Referenced in the notes to Table 3 of the paper.
estpost summarize l3NBS_B_Ins l3NBS_B_InsW l3NBS_B_Civ l3NBS_B_Poli         ///
                  l3Count_Ins l3Count_InsW l3Count_Civ l3Count_Poli         ///
                  l1NBS_B_Ins l1NBS_B_InsW l1NBS_B_Civ l1NBS_B_Poli         ///
                  l1Count_Ins l1Count_InsW l1Count_Civ l1Count_Poli
esttab using "$t3_doc.rtf", append                                    ///
    cells("count(fmt(%12.0fc)) mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.2f)) max(fmt(%9.2f))")                                ///
    collabels("Obs" "Mean" "Std. Dev." "Min" "Max")                         ///
    label nomtitle nonumber noobs                                           ///
    addnotes("Robustness variants: NBS-B and NBS-Count (available upon request).")

*--- Sample size checks quoted in the text -------------------------------------*
count                                              // expect 17,978
quietly levelsof Numeric_Country, local(ctys)
display "Number of countries: " `: word count `ctys''   // expect 16
count if !missing(Output_Growth, l3NBS_A_4)        // Table 4, cols 1-3

restore


*==============================================================================*
*  PART VI. TABLE 4 - FIRMS' PERFORMANCE AND POLITICAL VIOLENCE                *
*==============================================================================*
*  Dimension _4 = political violence. Columns 1-3: sales growth (t-3 lags);
*  columns 4-6: sales levels (t-1 lags). Within each block the three columns
*  are Index A (baseline, "NBS"), Index B ("NBS-B") and raw counts ("NBS-Count").

*--- Columns 1-3: sales growth -------------------------------------------------*
forvalues c = 1/3 {

    if `c' == 1 local v "l3NBS_A_4"
    if `c' == 2 local v "l3NBS_B_4"
    if `c' == 3 local v "l3NBS_Count_4"

    if `c' == 1 local hdr ""
    if `c' == 2 local hdr "Growth"
    if `c' == 3 local hdr ""

    preserve
    xtmixed Output_Growth `v' $controls $fixed_effects, ///
            cluster($clvar) || $revar:, mle variance
    * e(N_g) is a matrix; store its single element as a scalar so that
    * esttab can print it (this is why the row came out empty before).
    estadd scalar ng = e(N_g)[1,1]
    local ng = e(N_g)[1,1]   // actual number of countries in this estimation sample
    eststo t4_`c'

    *--- Sanity check: report the actual level-2 structure once ----------------*
    * In `mixed', e(N_g) is a MATRIX (one entry per random-effects level), which
    * is why esttab could not print it as a scalar before estadd was added.
    * This must read 16. Anything in the thirties means the estimation fell back
    * on the survey identifier (country x wave) and the run should be stopped.
    if `c' == 1 {
        display as text _n "=== level-2 groups actually used by xtmixed (expect 16) ==="
        matrix list e(N_g)
        * NB: do not use levelsof on `country'. It is a string containing spaces
        * and apostrophes ("Cote d'Ivoire2016"), which breaks macro parsing and
        * raises r(198). Count distinct values with a tag instead.
        tempvar tagw tagc
        quietly egen `tagw' = tag(country)
        quietly count if `tagw'
        local nw = r(N)
        quietly egen `tagc' = tag(Numeric_Country)
        quietly count if `tagc'
        local nc = r(N)
        display as text "country (survey id, country x wave) : `nw' groups"
        display as text "Numeric_Country (true country)     : `nc' groups"
        display as text "clustering / RE variable in use: $clvar" _n
    }

    if `c' == 1 {
        outreg using "$t4_doc.doc", replace ///
            keep(`v') se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`hdr'" \ "", "(`c')") ///
            title(Table 4. Firms' Performance and Political Violence)
    }
    else {
        outreg using "$t4_doc.doc", merge ///
            keep(`v') se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`hdr'" \ "", "(`c')")
    }
    restore
}

*--- Columns 4-6: sales levels -------------------------------------------------*
forvalues c = 4/6 {

    if `c' == 4 local v "l1NBS_A_4"
    if `c' == 5 local v "l1NBS_B_4"
    if `c' == 6 local v "l1NBS_Count_4"

    if `c' == 5 local hdr "Sales"
    else        local hdr ""

    preserve
    xtmixed stdlogoutput `v' $controlls $fixed_effects, ///
            cluster($clvar) || $revar:, mle variance
    * e(N_g) is a matrix; store its single element as a scalar so that
    * esttab can print it (this is why the row came out empty before).
    estadd scalar ng = e(N_g)[1,1]
    local ng = e(N_g)[1,1]   // actual number of countries in this estimation sample
    eststo t4_`c'
    outreg using "$t4_doc.doc", merge ///
        keep(`v') se bdec(2) starlevels(10 5 1) ba(arial) ///
        addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
        summstat(N_l2) landscape ///
        ctitles("", "" \ "", "`hdr'" \ "", "(`c')")
    restore
}



*--- LaTeX fragment for the manuscript ---------------------------------------*
esttab t4_1 t4_2 t4_3 t4_4 t4_5 t4_6 using "$t4_doc.tex", replace             ///
    keep(l3NBS_A_4 l3NBS_B_4 l3NBS_Count_4 l1NBS_A_4 l1NBS_B_4 l1NBS_Count_4) ///
    coeflabels(l3NBS_A_4 "NBS (t-3)" l3NBS_B_4 "NBS-B (t-3)"                  ///
               l3NBS_Count_4 "NBS-Count (t-3)" l1NBS_A_4 "NBS (t-1)"          ///
               l1NBS_B_4 "NBS-B (t-1)" l1NBS_Count_4 "NBS-Count (t-1)")       ///
    b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)                                  ///
    mgroups("Growth" "Sales", pattern(1 0 0 1 0 0))                           ///
    stats(N ng, labels("Observations" "Level-2 groups") fmt(%12.0fc %9.0f))  ///
    booktabs nomtitle nonumber fragment                                       ///
    addnotes("$texnote")

*==============================================================================*
*  PART VII. TABLE 5 - HETEROGENEITY BY FIRM SIZE                              *
*==============================================================================*
*  The size dummies are dropped from the control set because they define the
*  sample split ($controll / $controlll).

*--- Columns 1-3: sales growth, by size ----------------------------------------*
forvalues c = 1/3 {

    if `c' == 1 local lbl "Small firms"
    if `c' == 2 local lbl "Medium firms"
    if `c' == 3 local lbl "Large firms"

    preserve
    xtmixed Output_Growth l3NBS_A_4 $controll $fixed_effects if size == `c', ///
            cluster($clvar) || $revar:, mle variance
    * e(N_g) is a matrix; store its single element as a scalar so that
    * esttab can print it (this is why the row came out empty before).
    estadd scalar ng = e(N_g)[1,1]
    local ng = e(N_g)[1,1]   // actual number of countries in this estimation sample
    eststo t5_`c'

    if `c' == 1 {
        outreg using "$t5_doc.doc", replace ///
            keep(l3NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`lbl'" \ "", "(`c')") ///
            title(Table 5. Firms' Performance and Political Violence: By size)
    }
    else {
        outreg using "$t5_doc.doc", merge ///
            keep(l3NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`lbl'" \ "", "(`c')")
    }
    restore
}

*--- Columns 4-6: sales levels, by size ----------------------------------------*
*  All six columns use the political violence dimension (_4). Earlier drafts
*  ran columns 4-6 on l1NBS_A_1 (instability OF the regime), which mixed two
*  different dimensions inside a single table; see [F1].

forvalues s = 1/3 {

    local c = `s' + 3
    if `s' == 1 local lbl "Small firms"
    if `s' == 2 local lbl "Medium firms"
    if `s' == 3 local lbl "Large firms"

    preserve
    xtmixed stdlogoutput l1NBS_A_4 $controlll $fixed_effects if size == `s', ///
            cluster($clvar) || $revar:, mle variance
    * e(N_g) is a matrix; store its single element as a scalar so that
    * esttab can print it (this is why the row came out empty before).
    estadd scalar ng = e(N_g)[1,1]
    local ng = e(N_g)[1,1]   // actual number of countries in this estimation sample
    eststo t5_`c'
    outreg using "$t5_doc.doc", merge ///
        keep(l1NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
        addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
        summstat(N_l2) landscape ///
        ctitles("", "" \ "", "`lbl'" \ "", "(`c')")
    restore
}



*--- LaTeX fragment for the manuscript ---------------------------------------*
esttab t5_1 t5_2 t5_3 t5_4 t5_5 t5_6 using "$t5_doc.tex", replace             ///
    keep(l3NBS_A_4 l1NBS_A_4)                                                 ///
    coeflabels(l3NBS_A_4 "NBS (t-3)" l1NBS_A_4 "NBS (t-1)")                   ///
    b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)                                  ///
    mgroups("Growth" "Sales", pattern(1 0 0 1 0 0))                           ///
    mtitles("Small" "Medium" "Large" "Small" "Medium" "Large")                ///
    stats(N ng, labels("Observations" "Level-2 groups") fmt(%12.0fc %9.0f))  ///
    booktabs nonumber fragment                                                ///
    addnotes("$texnote")

*==============================================================================*
*  PART VIII. TABLE 6 - HETEROGENEITY BY OWNERSHIP AND SECTOR                  *
*==============================================================================*
*  The dependent variable is sales growth in all four columns.
*  [F2] The split uses the domestic / foreign dummies built in PART IV, i.e.
*  majority ownership (>= 51 percent). The original code split on b2a >= 50 and
*  b2b >= 50, which put a firm held exactly 50/50 into BOTH columns. Sample
*  sizes therefore differ slightly from earlier drafts.

forvalues c = 1/4 {

    if `c' == 1 {
        local lbl "Domestic firms"
        local cond "domestic == 1"
    }
    if `c' == 2 {
        local lbl "Foreign firms"
        local cond "foreign == 1"
    }
    if `c' == 3 {
        local lbl "Manufacturing"
        local cond `"Sector == "Manufacturing""'
    }
    if `c' == 4 {
        local lbl "Service"
        local cond `"Sector == "Service""'
    }

    preserve
    xtmixed Output_Growth l3NBS_A_4 $controls $fixed_effects if `cond', ///
            cluster($clvar) || $revar:, mle variance
    * e(N_g) is a matrix; store its single element as a scalar so that
    * esttab can print it (this is why the row came out empty before).
    estadd scalar ng = e(N_g)[1,1]
    local ng = e(N_g)[1,1]   // actual number of countries in this estimation sample
    eststo t6_`c'

    if `c' == 1 {
        outreg using "$t6_doc.doc", replace ///
            keep(l3NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`lbl'" \ "", "(`c')") ///
            title(Table 6. Firms' Performance and Political Violence: By ownership and sector)
    }
    else {
        outreg using "$t6_doc.doc", merge ///
            keep(l3NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`lbl'" \ "", "(`c')")
    }
    restore
}



*--- LaTeX fragment for the manuscript ---------------------------------------*
esttab t6_1 t6_2 t6_3 t6_4 using "$t6_doc.tex", replace                       ///
    keep(l3NBS_A_4) coeflabels(l3NBS_A_4 "NBS (t-3)")                         ///
    b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)                                  ///
    mgroups("Ownership" "Sector", pattern(1 0 1 0))                           ///
    mtitles("Domestic" "Foreign" "Manufacturing" "Service")                   ///
    stats(N ng, labels("Observations" "Level-2 groups") fmt(%12.0fc %9.0f))  ///
    booktabs nonumber fragment                                                ///
    addnotes("$texnote")

*==============================================================================*
*  PART IX. TABLE 7 - HETEROGENEITY BY OWNERSHIP AND SECTOR, SALES LEVELS      *
*==============================================================================*
*  Mirrors Table 6 on the other margin: same four splits, but the dependent
*  variable is the standardized log of real sales rather than sales growth, and
*  instability enters at t-1 with the matching control set ($controlls), exactly
*  as in the sales-level columns of Tables 4 and 5.

forvalues c = 1/4 {

    if `c' == 1 {
        local lbl "Domestic firms"
        local cond "domestic == 1"
    }
    if `c' == 2 {
        local lbl "Foreign firms"
        local cond "foreign == 1"
    }
    if `c' == 3 {
        local lbl "Manufacturing"
        local cond `"Sector == "Manufacturing""'
    }
    if `c' == 4 {
        local lbl "Service"
        local cond `"Sector == "Service""'
    }

    preserve
    xtmixed stdlogoutput l1NBS_A_4 $controlls $fixed_effects if `cond', ///
            cluster($clvar) || $revar:, mle variance
    estadd scalar ng = e(N_g)[1,1]
    local ng = e(N_g)[1,1]
    eststo t7_`c'

    if `c' == 1 {
        outreg using "$t7_doc.doc", replace ///
            keep(l1NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`lbl'" \ "", "(`c')") ///
            title(Table 7. Firms' Sales and Political Violence: By ownership and sector)
    }
    else {
        outreg using "$t7_doc.doc", merge ///
            keep(l1NBS_A_4) se bdec(2) starlevels(10 5 1) ba(arial) ///
            addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
            summstat(N_l2) landscape ///
            ctitles("", "" \ "", "`lbl'" \ "", "(`c')")
    }
    restore
}



*--- LaTeX fragment for the manuscript ---------------------------------------*
esttab t7_1 t7_2 t7_3 t7_4 using "$t7_doc.tex", replace                       ///
    keep(l1NBS_A_4) coeflabels(l1NBS_A_4 "NBS (t-1)")                         ///
    b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)                                  ///
    mgroups("Ownership" "Sector", pattern(1 0 1 0))                           ///
    mtitles("Domestic" "Foreign" "Manufacturing" "Service")                   ///
    stats(N ng, labels("Observations" "Level-2 groups") fmt(%12.0fc %9.0f))  ///
    booktabs nonumber fragment                                                ///
    addnotes("$texnote")

*==============================================================================*
*  PART X. OTHER DIMENSIONS - AVAILABLE UPON REQUEST                           *
*==============================================================================*
*  The paper reports political violence (_4) only and states that estimates for
*  the other three dimensions are available upon request. The block below
*  produces them. It also subsumes the duplicated block at the end of the
*  original Estimates.do (see [F3]), which re-ran Table 4 with dimension _1.

global run_other_dims 0

if $run_other_dims {

    forvalues dim = 1/3 {

        if `dim' == 1 local dlbl "Instability of regime"
        if `dim' == 2 local dlbl "Instability within regime"
        if `dim' == 3 local dlbl "Mass civil protest"

        forvalues c = 1/3 {
            if `c' == 1 local v "l3NBS_A_`dim'"
            if `c' == 2 local v "l3NBS_B_`dim'"
            if `c' == 3 local v "l3NBS_Count_`dim'"

            preserve
            xtmixed Output_Growth `v' $controls $fixed_effects, ///
                    cluster($clvar) || $revar:, mle variance
            local ng = e(N_g)[1,1]
            if `c' == 1 {
                outreg using "$tables/Dimension_`dim'.doc", replace ///
                    keep(`v') se bdec(2) starlevels(10 5 1) ba(arial) ///
                    addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
                    summstat(N_l2) landscape ///
                    ctitles("", "" \ "", "Growth" \ "", "(`c')") ///
                    title(Firms' Performance and `dlbl')
            }
            else {
                outreg using "$tables/Dimension_`dim'.doc", merge ///
                    keep(`v') se bdec(2) starlevels(10 5 1) ba(arial) ///
                    addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
                    summstat(N_l2) landscape ///
                    ctitles("", "" \ "", "Growth" \ "", "(`c')")
            }
            restore
        }

        forvalues s = 1/3 {
            local c = `s' + 3
            if `s' == 1 local v "l1NBS_A_`dim'"
            if `s' == 2 local v "l1NBS_B_`dim'"
            if `s' == 3 local v "l1NBS_Count_`dim'"

            preserve
            xtmixed stdlogoutput `v' $controlls $fixed_effects, ///
                    cluster($clvar) || $revar:, mle variance
            local ng = e(N_g)[1,1]
            outreg using "$tables/Dimension_`dim'.doc", merge ///
                keep(`v') se bdec(2) starlevels(10 5 1) ba(arial) ///
                addrows("Control Variables", "Yes" \ "# Countries", "`ng'" \ "- Fixed Effects: Country, Year", "Yes") ///
                summstat(N_l2) landscape ///
                ctitles("", "" \ "", "Sales" \ "", "(`c')")
            restore
        }
    }
}

}   // end run_tables

log close

*==============================================================================*
*                                  END OF FILE                                 *
*==============================================================================*
