#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Newspaper Sentiment Analysis for West and Central African Countries
# Authors: Philipp Kronenberg, Pierre Jean-Claude Mandon
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Clean Console and Environment
rm(list = ls())
cat("\014")


# Packages ----------------------------------------------------------------

library(tidyr) 
library(tidyverse)
library(dplyr)
library(countrycode)
library(readxl)


# Preliminaries -----------------------------------------------------------

# Load functions
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

# Define working directory
wd <- package_root()
benchmark_dir <- first_existing_path(
  package_path("Data", "Raw", "public", "benchmark_data"),
  non_package_path("private_data", "Data", "benchmark data")
)
benchmark_file <- function(...) {
  file.path(benchmark_dir, ...)
}
benchmark_figure_dir <- dirname(
  ensure_parent_dir(
    non_package_path("Outputs", "Annex", "benchmark_figures", "placeholder.txt")
  )
)
ggsave <- function(...) {
  invisible(NULL)
}

## Load the count data
load(derived_path("prepared_data_NBS.rda"))

## Save list elements as separate objects in the global environment
list2env(metadata, envir = .GlobalEnv)

# Create output list
benchmark_data_list <- list()


### Benchmark Data ----------------------------------------------------------

# ACLED -------------------------------------------------------------------
# newspaper based, daily, 1997-2024
# contains all 16 countries 

# # Load ACLED data
# df.acled.in <- read_csv(paste0(wd,"/Data/benchmark data/ACLED/Africa_1997-2025_Jan17.csv")) %>% 
#   as.tibble() %>%
#   mutate( Date = as.Date(event_date, format='%d/%m/%Y')) %>%
#   mutate( cty = countrycode( country, 'country.name', 'iso3c' ) )

# Save raw data after basic data preparation as raw data is too large for Git
#save(df.acled.in, file = benchmark_file("ACLED", "df_acled_in.rda"))
load(benchmark_file("ACLED", "df_acled_in.rda"))

# Filter and select relevant countries and variables
df.acled <- df.acled.in %>%
  correct_identifier("cty", "country") %>%
  filter(cty %in% country_codes) %>%
  select(cty, country, Date, event_type, sub_event_type)

# Aggregate the event_type column by Date and cty
df.acled_long <- df.acled %>%
  group_by(country, Date, event_type) %>%
  summarize(event_count = n(), .groups = 'drop')

df.acled_long <- df.acled_long %>%
  group_by(event_type, country) %>%                                   # Group by 'event_type' and 'country'
  complete(Date = seq(min(Date), max(Date), by = "day")) %>%      # Complete missing dates
  filter(Date >= as.Date("1990-01-01")) %>%                       # Fill missing dates 
  mutate(event_count = replace_na(event_count, 0)) %>%            # Replace NA with 0 for event_count
  mutate(Date = floor_date(Date, "month")) %>%                    # Convert Date to the first day of the month
  group_by(event_type, country, Date) %>%                             # Group by 'event_type', 'country', and Month
  summarise(event_count = sum(event_count, na.rm = TRUE), .groups = 'drop') %>% # Summarize event_count
  rename(date = Date, count = event_count) %>%
  mutate(count = as.numeric(count)) %>%
  mutate(event_type = str_replace(event_type, "Explosions/Remote violence", "Explosions"))
  
acled_plot <- ggplot(df.acled_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "ACLED counts by Country and Topic",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(benchmark_figure_dir, "acled_plot.pdf"), plot = acled_plot, width = 14, height = 10)

# Barrett et al (2022) Events ------------------------------------------------

# Load rdata file
load(benchmark_file("Barret et al", "events.rdata"))

# Select columns and filter countries
df.events <- events.out %>%
  correct_identifier("cty", "cty.name") %>%
  select(Date, cty, cty.name, contains('event')) %>%
  filter(cty %in% country_codes)

# Transform wide to long table
df.events_long <- df.events %>%
  pivot_longer(
    cols = starts_with("event"),   # This selects columns starting with 'event'
    names_to = "event_type",
    values_to = "event_count"
  ) %>%
  mutate(event_count = as.integer(event_count)) %>%  # Convert TRUE to 1 and FALSE to 0
  group_by(Date, cty.name, event_type) %>%
  summarise(event_count = sum(event_count), .groups = 'drop')

barret_event_data_long <- df.events_long %>%
  filter(event_count == 1) %>%                                   # Filter for relevant rows
  group_by(cty.name) %>%                                              # Group by country
  complete(Date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month"))%>%           # Replace NA with 0 for event_count
  filter(Date >= as.Date("1990-01-01")) %>% # Fill missing dates
  mutate(event_count = replace_na(event_count, 0)) %>%           # Replace NA with 0 for event_count
  arrange(cty.name, Date) %>%                                         # Ensure correct ordering by country and date
  rename(country = cty.name, date = Date, count = event_count) %>%
  mutate(event_type = "Civil Unrest")

event_plot <- ggplot(barret_event_data_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "RSUI Events by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "barret_event_plot.pdf"), plot = event_plot, width = 14, height = 10)



# CNTS Data Archive -------------------------------------------------------
# annual, 1962-2023
# Annual count and index data, for many indicators a lot of missing data

# Read excel file
df.cnts.in <- read_excel(benchmark_file("CNTS Data Archive", "2023_Edition_CNTSDATA.xlsx")) %>% 
  as.tibble() 

# Select relevant columns
df.cnts <- df.cnts.in %>%
  correct_identifier("World Bank Code", "Country") %>%
  select(which(grepl("^(domestic|legis|polis|year)", df.cnts.in[1, ], ignore.case = TRUE)), Country) %>%
  slice(-1) %>%
  filter(Country %in% country_to_region$country_name)

# Transform wide to long table
df.cnts_long <- df.cnts %>%
  pivot_longer(
    cols = -c(Country, Year),
    names_to = "event_type",
    values_to = "event_count"
  ) %>%
  rename(Date = Year)

df.cnts_long_monthly <- df.cnts_long %>%
  mutate(event_count = as.numeric(event_count)) %>%              # Convert event_count to numeric
  mutate(Date = as.Date(paste0(Date, "-01-01"))) %>%            # Convert year to a Date (YYYY-01-01)
  group_by(event_type, Country) %>%
  complete(Date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month"))%>%           # Replace NA with 0 for event_count
  filter(Date >= as.Date("1990-01-01")) %>% # Fill missing dates# Group by 'event_type' and 'cty'
  mutate(event_count = replace_na(event_count, 0)) %>%          # Replace NA with 0
  #mutate(Date = floor_date(Date, "month")) %>%  
  group_by(event_type, Country, Date) %>%                           # Group by 'event_type', 'cty', and Month
  summarise(event_count = sum(event_count, na.rm = TRUE), .groups = 'drop') %>%  # Aggregate event_count by month
  rename(date = Date, count = event_count, country = Country) %>%
  mutate(event_type = str_replace_all(event_type, 
                                      "Size of Legislature/Number of Seats, Largest Party \\(Scaling: 0\\.01\\)", 
                                      "Size of Legislature Scaled"
  ))
  
cnts_plot <- ggplot(df.cnts_long_monthly, aes(x = date, y = count, color = country)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ event_type, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Count by Country and Topic",
       x = "Date",
       y = "Value") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "cnts_plot.pdf"), plot = cnts_plot, width = 14, height = 10)

# Note: For some measures a country average and for some a country sum would make sense...


# CSP Database ------------------------------------------------------------

# Center for Systemic Peace, Coups d'Etat, 1946-2021 ----------------------

# Only the annual coup series from CSP is retained in the formal package.

# Define the file path
file_path <- benchmark_file("CSP Database", "Center for Systemic Peace, Coups d'Etat, 1946-2021", "CSPCoupsAnnualv2021.xls")

# Read the Excel file
df.csp_coup_ann_data.in <- read_excel(file_path)

summarized_data <- df.csp_coup_ann_data.in %>%
  mutate(
    coup_sum = scoup1 + atcoup2 + pcoup3 + apcoup4,
    non_coup_sum = agcoup + foroutex + reboutex + assassex + resignex,
    total_sum = scoup1 + atcoup2 + pcoup3 + apcoup4 + agcoup + foroutex + reboutex + assassex + resignex
  ) %>%
  group_by(country, year) %>%
  summarise(
    coup_sum = sum(coup_sum, na.rm = TRUE),
    non_coup_sum = sum(non_coup_sum, na.rm = TRUE),
    total_sum = sum(total_sum, na.rm = TRUE)
  ) %>%
  ungroup()

df.csp_coup_ann_data <- df.csp_coup_ann_data.in %>%
  left_join(summarized_data, by = c("country", "year"))
  
df.csp_coup_ann_data <- df.csp_coup_ann_data %>%
  correct_identifier("scode", "country") %>%
  filter(country %in% country_to_region$country_name) %>%
  mutate(date = as.Date(paste0(year, "-01-01"))) %>%         # Convert year to a Date (YYYY-01-01)
  select(-ccode, -scode, -year)

df.csp_coup_ann_data <- df.csp_coup_ann_data %>%
  group_by(country) %>%                                                                 # Group by country
  complete(date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month")) %>%  # Replace NA with 0 for event_count
  mutate(across(where(is.double), ~ replace_na(.x, 0))) %>% 
  filter(date >= as.Date("1990-01-01")) %>%                                             # Fill missing dates
  arrange(country, date)                                                           # Ensure correct ordering by country and date

df.csp_coup_ann_data_long <- df.csp_coup_ann_data %>%
  pivot_longer(
    cols = scoup1:total_sum,  # Select all event columns
    names_to = "event_type",  # New column for event types
    values_to = "count"       # New column for values
  ) %>%
  filter(event_type == "total_sum") %>%
  mutate(event_type = "CSP Annual Coups")

# This variable represents the total number of all forced leadership change events, combining both coup-related and non-coup events.
  
csp_coup_ann_plot <- ggplot(df.csp_coup_ann_data_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Event by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "csp_coup_ann_plot.pdf"), plot = csp_coup_ann_plot, width = 14, height = 10)



# POLITY5 Political Regime Characteristics and Transitions, 1800-2 --------

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Polity5 Project, Political Regime Characteristics and Transitions, 1800-2018", "p5v2018.xls")

# Read the Excel file
df.csp_polity_data.in <- read_excel(file_path)

df.csp_polity_data_long <- df.csp_polity_data.in %>%
  correct_identifier("scode", "country") %>%
  filter(country %in% country_to_region$country_name) %>%
  select(country, year, democ, autoc, polity2)

df.csp_polity_data_long <- df.csp_polity_data_long %>%
  group_by(country) %>%                                      # Group by country
  mutate(date = as.Date(paste0(year, "-01-01"))) %>%         # Convert year to a Date (YYYY-01-01)
  #complete(date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month")) %>%  # Replace NA with 0 for event_count
  mutate(across(where(is.double), ~ replace_na(.x, 0))) %>% 
  filter(date >= as.Date("1990-01-01")) %>%                                             # Fill missing dates
  arrange(country, date) %>%                                                              # Ensure correct ordering by country and date
  select(-year)
  
df.csp_polity_data_long <- df.csp_polity_data_long %>%
  pivot_longer(
    cols = democ:polity2,  # Select all event columns
    names_to = "event_type",  # New column for event types
    values_to = "count"       # New column for values
  )

csp_polity_plot <- ggplot(df.csp_polity_data_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Score by Country",
       x = "Date",
       y = "Score",
       color = "Legend") +  # Add a legend label
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "csp_polity_plot.pdf"), plot = csp_polity_plot, width = 14, height = 10)


# Database of Political Institutions (World Bank) -------------------------
# Annual

# Read excel file
df.dpi.in <- read_excel(benchmark_file("Database of Political Institutions (World Bank)", "dpi2012.xls"))

# Select relevant columns and preprocess data
df.dpi_long <- df.dpi.in %>%
  correct_identifier(country_name_col = "countryname") %>%
  select(year, countryname, yrsoffc, prtyin, govfrac, frac, maj) %>%
  filter(countryname %in% country_to_region$country_name) %>%
  mutate(across(c(yrsoffc, prtyin, govfrac, frac, maj), as.numeric)) %>%
  mutate(across(everything(), ~ replace(., . == -999, NA))) %>%
  mutate(across(everything(), ~ replace(., . == "NA", NA))) %>%
  mutate(across(where(is.numeric), ~ replace_na(., 0))) %>% # Replace NA with 0 in numeric columns
  mutate(across(where(is.character), ~ replace_na(., ""))) %>% # Replace NA with "" in character columns
  rename(date = year, country = countryname) %>%
  mutate(date = as.Date(paste0(date, "-01-01"))) %>%
  filter(date >= 1992)

df.dpi_long <- df.dpi_long %>%
  pivot_longer(
    cols = yrsoffc:maj,  # Select all event columns
    names_to = "event_type",  # New column for event types
    values_to = "count"       # New column for values
  ) %>%
  mutate(
    event_type = case_when(
      event_type == "yrsoffc"    ~ "Years in Office",
      event_type == "prtyin"   ~ "Party in Power",
      event_type == "govfrac"    ~ "Government Fractionalization",
      event_type == "frac"   ~ "Legislative Fractionalization",
      event_type == "maj"    ~ "Majority Party Indicator",
      TRUE ~ event_type  # Keep original name if not listed
    )
  )

df.dpi_index_long <- df.dpi_long %>%
  filter(event_type %in% c("Government Fractionalization", "Legislative Fractionalization", "Majority Party Indicator"))

df.dpi_years_long <- df.dpi_long %>%
  filter(event_type %in% c("Years in Office", "Party in Power"))


dpi_index_plot <- ggplot(df.dpi_index_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Index by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
  #scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "dpi_index_plot.pdf"), plot = dpi_index_plot, width = 14, height = 10)

dpi_year_plot <- ggplot(df.dpi_years_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Index by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "dpi_year_plot.pdf"), plot = dpi_year_plot, width = 14, height = 10)


#yrsoffc (Years in Office)
#This variable measures the number of years the chief executive (president or prime minister) has been in office.
#It helps assess political stability and the tenure of leaders over time.

#prtyin (Party in Power)
#Indicates whether the current government is a continuation of the same party from the previous year.
#A value of 1 suggests continuity, while 0 means a change in ruling party.

#herftot (Herfindahl Index of Government Fragmentation)
#Measures government fragmentation based on the Herfindahl index, which quantifies the concentration of power among ruling parties.
#A higher value indicates less fragmented (more concentrated) government control, while a lower value suggests more political diversity and coalition-based governance.

#govfrac (Government Fractionalization)
#Captures how divided the government is among different parties.
#Calculated based on the probability that two randomly chosen members of the government are from different parties.
#Higher values indicate greater fragmentation.

#frac (Legislative Fractionalization)
#Measures fragmentation in the legislature (parliament or congress) using a similar Herfindahl index-based approach as govfrac.
#Reflects the extent to which power is dispersed among multiple parties in the legislature.

#maj (Majority Party Indicator)
#Indicates whether a single party holds a majority in the legislature.
#A value of 1 means the ruling party has a majority, while 0 means no single party has majority control.



# Gallup ------------------------------------------------------------------
# annual data from surveys, starts about 2006
# Missing: Equatorial Guinea, Guinea-Bissau

# Read excel files, rescale index, and select columns
df.gallup_leadership.in <- read_excel(benchmark_file("GALLUP", "GallupAnalytics_Export_20240823_141734.xlsx"), sheet = "Approval of Country's Leadershi", skip =7) %>% 
  as.tibble() %>%
  correct_identifier(country_name_col = "Geography") %>%
  mutate(net_score = Approve - Disapprove) %>%
  mutate(leadership_index = scales::rescale(net_score, to = c(0,100))) %>%
  select(Geography, Time, leadership_index)

df.gallup_government.in <- read_excel(benchmark_file("GALLUP", "GallupAnalytics_Export_20240823_141734.xlsx"), sheet = "Confidence in National Governme", skip =7) %>% 
  as.tibble() %>%
  correct_identifier(country_name_col = "Geography") %>%
  mutate(net_score = Yes - No) %>%
  mutate(government_index = scales::rescale(net_score, to = c(0,100))) %>%
  select(Geography, Time, government_index)

df.gallup_corruption.in <- read_excel(benchmark_file("GALLUP", "GallupAnalytics_Export_20240823_141734.xlsx"), sheet = "Corruption in Government", skip =7) %>% 
  as.tibble() %>%
  correct_identifier(country_name_col = "Geography") %>%
  mutate(net_score = Yes - No) %>%
  mutate(corruption_index = scales::rescale(net_score, to = c(0,100))) %>%
  select(Geography, Time, corruption_index)

df.gallup_election.in <- read_excel(benchmark_file("GALLUP", "GallupAnalytics_Export_20240823_141734.xlsx"), sheet = "Honesty of Elections", skip =7) %>% 
  as.tibble() %>%
  correct_identifier(country_name_col = "Geography") %>%
  mutate(net_score = Yes - No) %>%
  mutate(election_index  = scales::rescale(net_score, to = c(0,100))) %>%
  select(Geography, Time, election_index)

# Merge tables
df_gallup_list <- list(df.gallup_leadership.in, df.gallup_government.in, df.gallup_corruption.in, df.gallup_election.in)
df.gallup <- reduce(df_gallup_list, function(x, y) merge(x, y, by = c("Geography", "Time"), all = TRUE))

# Transform wide to long table
df.gallup_long <- df.gallup %>%
  pivot_longer(
    cols = -c(`Geography`, Time),
    names_to = "event_type",
    values_to = "count"
  ) %>%
  rename(
    country = Geography,
    date = Time
  ) %>%
  filter(country %in% country_to_region$country_name) %>%
  mutate(date = as.Date(paste0(date, "-01-01"))) %>%
  filter(date >= "1990-01-01")
 

gallup_plot <- ggplot(df.gallup_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Index by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "gallup_plot.pdf"), plot = gallup_plot, width = 14, height = 10)



# ICRG data ----------------------------------------------------------
# Monthly subjective risk data, start 1984
# Missing: Equatorial Guinea

# Read csv from Barret
df.ircg.in <- read_delim(benchmark_file("ICRG sample (not free)", "Barrett Replication Code", "ICRG_CountryData.csv"), ';')

# Prepare code according to Barret
df.ircg <- df.ircg.in %>%
  rename( variable=Variable, country=Country ) %>%
  gather( Date, value, -country, - variable ) %>%
  filter( !is.na(variable) ) %>%
  mutate( variable = paste0(variable %>% gsub( ' \\(D\\)', '', . ) %>% gsub( ' ', '.', . ) %>% tolower ),
          cty = country %>% countrycode( 'country.name', 'iso3c'),
          Date = paste0( '01/', Date ) %>% as.Date( format='%d/%m/%Y' ) ) %>% 
  arrange(Date)

# The ICRG data
df.ircg.idx <- df.ircg %>%
  correct_identifier("cty", "country") %>%
  group_by( cty, country, variable ) %>%
  mutate( value = 200 - 100 * value / mean(value, na.rm=T) ) %>%
  ungroup() %>%
  spread( variable, value ) %>%
  select( country, Date, everything(), -cty ) %>%
  group_by( country, Date ) %>%
  summarise_all( mean, na.rm=T ) %>%
  ungroup()

# Filter for country code
df.ircg.idx <- df.ircg.idx %>%
  filter(country %in% country_to_region$country_name) %>%
  #mutate(date = as.Date(date)) %>%
  filter(Date >= "1990-01-01") %>%
  rename(date = Date)

# Transform wide to long table
df.ircg.idx_long <- df.ircg.idx %>%
  pivot_longer(
    cols = -c(country, date),
    names_to = "event_type",
    values_to = "count") %>%
  mutate(count = replace_na(count, 0))

ircg_plot <- ggplot(df.ircg.idx_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Index by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "ircg_plot.pdf"), plot = ircg_plot, width = 14, height = 10)



# Powell et al (2011) Coups --------------------------------------------------------------

# Powell, J.M., Thyne, C.L., 2011. Global instances of coups from 1950 to 2010: A new dataset. J. Peace Res. 48 (2), 249–259.
# Coup Data: Monthly binary data

df.coups.in <- read.table(benchmark_file("powell_thyne_coups", "powell_thyne_coups_final.txt"), header = TRUE, sep = "\t")

df.coups <- df.coups.in %>%
  mutate( Date = make_date(year, month, 1) ) %>%
  mutate( cty = countrycode( country, 'country.name', 'iso3c' ) ) %>%
  mutate( coup.success=(coup==2), coup.fail=(coup==1) ) %>%
  correct_identifier("cty", "country") %>%
  select(Date, country, contains('coup.') ) %>%
  filter(country %in% country_to_region$country_name)

df.coups_long <- df.coups %>%
  pivot_longer(
    cols = c(coup.success, coup.fail),
    names_to = "event_type",
    values_to = "count"
  ) %>%
  mutate(count = as.integer(count)) %>%  # Convert TRUE to 1 and FALSE to 0
  group_by(Date, country, event_type) %>%
  summarise(count = sum(count), .groups = 'drop')

df.coups_long <- df.coups_long %>%
  filter(count == 1) %>%                                   # Filter for relevant rows
  group_by(country) %>%                                              # Group by country
  complete(Date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month"))%>%           # Replace NA with 0 for count
  filter(Date >= as.Date("1990-01-01")) %>% # Fill missing dates
  mutate(count = replace_na(count, 0)) %>%           # Replace NA with 0 for count
  arrange(country, Date) %>%                                       # Ensure correct ordering by country and date
  rename(date = Date) %>%
  mutate(event_type = "Coups")

coup_plot <- ggplot(df.coups_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Coup by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "coup_plot.pdf"), plot = coup_plot, width = 14, height = 10)



## Ethnic Violence

# Missing: Equatorial Guinea, Gabon, Benin, Burkina Faso, Guinea-Bissau, Ghana, Mauritania

library(haven)
df.ucdp_esov.in <- read_dta(benchmark_file("UCDP dataset", "The Ethnic One-Sided Violence (EOSV) Dataset", "EOSV Dataset.dta"))

df.ucdp_esov_long <- df.ucdp_esov.in %>%
  select(Year, BestFatalityEstimate, Location) %>%
  separate_rows(Location, sep = ",") %>%
  correct_identifier(country_name_col = "Location") %>%
  filter(Location %in% country_to_region$country_name) %>%
  rename(date =Year, country = Location) %>%
  mutate(date = as.Date(paste0(date, "-01-01"))) %>% 
  filter(date >= as.Date("1990-01-01")) %>%                                         
  arrange(country, date) %>%
  group_by(country, date) %>%
  summarise(count = sum(BestFatalityEstimate, na.rm = TRUE), .groups = 'drop') %>%
  group_by(country) %>%                                              
  complete(date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month"))%>%
  mutate(count = replace_na(count, 0)) %>%
  mutate(event_type = "Ethnic Violence")

ucdp_esov_plot <- ggplot(df.ucdp_esov_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Event by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "ucdp_esov_plot.pdf"), plot = ucdp_esov_plot, width = 14, height = 10)


# World Bank Worldwide Governance Indicators ------------------------------------
# The six aggregate indicators are based on  over 30 underlying data sources reporting the perceptions of governance of a large number of survey  respondents and expert assessments worldwide.  
# Estimate of governance (ranges from approximately -2.5 (weak) to 2.5 (strong) governance performance)
# Annual from 1996 - 2022

# List the sheet names you want to read
sheet_names <- c("VoiceandAccountability", "Political StabilityNoViolence", "GovernmentEffectiveness", "RegulatoryQuality", "RuleofLaw", "ControlofCorruption")

# Function to process each sheet
process_sheet <- function(sheet_name) {
  df.in <- read_excel(benchmark_file("World Bank Worldwide Governance Indicators", "The Worldwide Governance Indicators.xlsx"), 
                      sheet = sheet_name, skip = 13, col_names = FALSE)
  
  df <- df.in %>%
    select(which(grepl("^(Code|Estimate)", df.in[2, ], ignore.case = TRUE))) %>%
    slice(-2) %>%
    {.[1, 1] <- "cty"; .} %>%
    {colnames(.) <- .[1, ]; .} %>%
    slice(-1) %>%
    pivot_longer(
      cols = -c(cty),
      names_to = "Date",
      values_to = "event_count"
    ) %>%
    mutate(event_type = sheet_name) %>%
    correct_identifier("cty") %>%
    filter(cty %in% country_codes)
  
  return(df)
}

# Apply the function to each sheet and combine results
df.wwgi_long <- map_dfr(sheet_names, process_sheet)

df.wwgi_long <- df.wwgi_long %>%
  left_join(country_to_region, by = c("cty" = "country_code")) %>%
  select(country_name, Date, event_count, event_type) %>%  # Replace 'cty' with 'country_name'
  mutate(event_count = as.double(event_count)) %>%
  rename(country = country_name, date = Date, count = event_count) %>%  # Rename for consistency
  mutate(date = as.Date(paste0(date, "-01-01"))) 

wwgi_plot <- ggplot(df.wwgi_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Event by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
  #scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "wwgi_plot.pdf"), plot = wwgi_plot, width = 14, height = 10)


# World Handbook of Political Indicators IV (WHIV) ------------------------

df.whiv.in <- read_delim(benchmark_file("World Handbook of Political Indicators IV (WHIV)", "WHIV (Daily-csv).csv"), ',')

df.whiv <- df.whiv.in %>%
  select(eventdate, eventform, tgtloc_wdi) %>%
  group_by(eventdate, eventform, tgtloc_wdi) %>%
  summarise(event_count = n(), .groups = 'drop')

# Filter for country code
df.whiv_long <- df.whiv %>%
  mutate(eventdate = dmy(format(dmy(eventdate), "%d-%m-%Y")))%>%
  rename(Date = eventdate,
         event_type = eventform, 
         cty = tgtloc_wdi) %>%
  correct_identifier("cty") %>%
  filter(cty %in% country_codes) %>%
  left_join(country_to_region, by = c("cty" = "country_code")) %>%
  select(-region, -cty)

# Add a new column 'topics' based on the conditions
df.whiv_long <- df.whiv_long %>%
  mutate(topics = case_when(
    event_type %in% c("POBS", "PMAR", "PPRO", "PALT", "PDEM", "SRAL", "STRI") ~ "Protest",
    event_type %in% c("BANA", "CENS", "MONI", "POAR") ~ "Political Sanctions",
    event_type %in% c("RPOL", "RSAN", "RCUR", "DMIN", "EMSA", "RELE", "RRPE", "RRPR") ~ "Political Relaxations",
    event_type %in% c("ABDU", "JACK", "HTAK", "PASS", "BEAT", "CORP", "SEXA", "MAIM",
                      "RAID", "ASSA", "COUP", "PEXE", "GRPG", "SBOM", "MINE", "VBOM", 
                      "AERI", "CONC", "RIOT", "CBRU", "CBIO") ~ "Violence",
    TRUE ~ NA_character_  # Assign NA for entries that don't match any category
  ))

# Add a new column with specific event labels
df.whiv_long <- df.whiv_long %>%
  mutate(event_label = case_when(
    event_type == "RIOT" ~ "Riots",
    event_type == "COUP" ~ "Coups",
    event_type == "ASSA" ~ "Assassinations",
    event_type == "STRI" ~ "Strikes",
    TRUE ~ NA_character_  # Assign NA for entries that don't match
  )) %>%
  select(-event_type) %>%
  rename(date = Date, country = country_name, count = event_count, event_type = topics) %>%
  mutate(count = as.double(count)) %>%
  mutate(date = floor_date(date, "month")) %>%
  group_by(country, event_type, date) %>%
  summarise(count = sum(count, na.rm = TRUE), .groups = "drop") %>%
  complete(country, event_type, date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month"),
    fill = list(count = 0))


whiv_plot <- ggplot(df.whiv_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Event by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "whiv_plot.pdf"), plot = whiv_plot, width = 14, height = 10)
### Error!!!

# Save Data ---------------------------------------------------------------

# Create a list containing all the data frames
benchmark_data_list <- list(
  df.acled_long = df.acled_long,
  barret_event_data_long = barret_event_data_long,
  df.cnts_long_monthly = df.cnts_long_monthly,
  df.csp_coup_ann_data_long = df.csp_coup_ann_data_long,
  df.csp_polity_data_long = df.csp_polity_data_long,
  df.dpi_long = df.dpi_long,
  df.gallup_long = df.gallup_long,
  df.ircg.idx_long = df.ircg.idx_long,
  df.coups_long = df.coups_long,
  df.ucdp_esov_long = df.ucdp_esov_long,
  df.wwgi_long = df.wwgi_long,  
  df.whiv_long = df.whiv_long
)

save(benchmark_data_list, file = derived_path("benchmark_data.rda"))


# Prepare benchmark data --------------------------------------------------

# Get the names of the list elements that contain "long"
long_names <- names(benchmark_data_list)[grepl("long", names(benchmark_data_list))]

# Create the long_table
benchmark_long_table <- long_names %>%
  map_dfr(~ mutate(benchmark_data_list[[.x]], source = .x))

# Save
save(benchmark_long_table, file = derived_path("benchmark_long_table.rda"))



