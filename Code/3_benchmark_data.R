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

# Afrobarometer -----------------------------------------------------------
# Short history, 1999?, annual, survey based

# # Load for reading .sav files
# library(haven)
# 
# # Define folder path
# folder_path <- paste0(wd, "/Data/benchmark data/Afrobarometer")
#   
# # Read all files in folder and make list
# file_list <- list.files(path = folder_path, pattern = "\\.sav$", full.names = TRUE)
# afro_list <- lapply(file_list, function(file) {
#   tryCatch({
#     read_sav(file, encoding = "latin1")
#   }, error = function(e) {
#     message("Error in file: ", file, " - ", e)
#     NULL  # Return NULL for problematic files
#   })
# })
# names(afro_list) <- tools::file_path_sans_ext(basename(file_list))
# 
# # Rename elements matching "r[0-9]" or "round-[0-9]"
# names(afro_list) <- sapply(names(afro_list), function(name) {
#   # Extract the number after "r" or "round-"
#   if (grepl("r[0-9]", name, ignore.case = TRUE)) {
#     gsub(".*r([0-9]+).*", "R\\1", name, ignore.case = TRUE)
#   } else if (grepl("round-[0-9]+", name, ignore.case = TRUE)) {
#     gsub(".*round-([0-9]+).*", "R\\1", name, ignore.case = TRUE)
#   } else {
#     name  # Leave the name unchanged if no match
#   }
# })
# 
# # Define the country mappings for each round
# country_mapping <- list(
#   R9 = c("2" = "Angola", "3" = "Benin", "4" = "Botswana", "5" = "Burkina Faso", "6" = "Cabo Verde", 
#          "7" = "Cameroon", "8" = "Congo-Brazzaville", "9" = "Côte d'Ivoire", "10" = "Eswatini", 
#          "11" = "Ethiopia", "12" = "Gabon", "13" = "Gambia", "14" = "Ghana", "15" = "Guinea", 
#          "16" = "Kenya", "17" = "Lesotho", "18" = "Liberia", "19" = "Madagascar", "20" = "Malawi", 
#          "21" = "Mali", "22" = "Mauritania", "23" = "Mauritius", "24" = "Morocco", "25" = "Mozambique", 
#          "26" = "Namibia", "27" = "Niger", "28" = "Nigeria", "29" = "São Tomé and Príncipe", 
#          "30" = "Senegal", "31" = "Seychelles", "32" = "Sierra Leone", "33" = "South Africa", 
#          "34" = "Sudan", "35" = "Tanzania", "36" = "Togo", "37" = "Tunisia", "38" = "Uganda", 
#          "39" = "Zambia", "40" = "Zimbabwe"),
#   R8 = c("2" = "Angola", "3" = "Benin", "4" = "Botswana", "5" = "Burkina Faso", "6" = "Cabo Verde", 
#          "7" = "Cameroon", "8" = "Côte d'Ivoire", "9" = "Eswatini", "10" = "Ethiopia", "11" = "Gabon", 
#          "12" = "Gambia", "13" = "Ghana", "14" = "Guinea", "15" = "Kenya", "16" = "Lesotho", 
#          "17" = "Liberia", "19" = "Malawi", "20" = "Mali", "21" = "Mauritius", "22" = "Morocco", 
#          "23" = "Mozambique", "24" = "Namibia", "25" = "Niger", "26" = "Nigeria", "28" = "Senegal", 
#          "29" = "Sierra Leone", "30" = "South Africa", "31" = "Sudan", "32" = "Tanzania", 
#          "33" = "Togo", "34" = "Tunisia", "35" = "Uganda", "36" = "Zambia", "37" = "Zimbabwe"),
#   R7 = c("1" = "Benin", "2" = "Botswana", "3" = "Burkina Faso", "4" = "Cabo Verde", "5" = "Cameroon", 
#          "6" = "Côte d'Ivoire", "7" = "eSwatini", "8" = "Gabon", "9" = "Gambia", "10" = "Ghana", 
#          "11" = "Guinea", "12" = "Kenya", "13" = "Lesotho", "14" = "Liberia", "15" = "Madagascar", 
#          "16" = "Malawi", "17" = "Mali", "18" = "Mauritius", "19" = "Morocco", "20" = "Mozambique", 
#          "21" = "Namibia", "22" = "Niger", "23" = "Nigeria", "24" = "São Tomé and Príncipe", 
#          "25" = "Senegal", "26" = "Sierra Leone", "27" = "South Africa", "28" = "Sudan", 
#          "29" = "Tanzania", "30" = "Togo", "31" = "Tunisia", "32" = "Uganda", "33" = "Zambia", 
#          "34" = "Zimbabwe"),
#   R6 = c("2" = "Benin", "3" = "Botswana", "4" = "Burkina Faso", "6" = "Cameroon", "7" = "Cabo Verde", 
#          "8" = "Côte d'Ivoire", "10" = "Gabon", "11" = "Ghana", "12" = "Guinea", "13" = "Kenya", 
#          "14" = "Lesotho", "15" = "Liberia", "16" = "Madagascar", "17" = "Malawi", "18" = "Mali", 
#          "19" = "Mauritius", "20" = "Morocco", "21" = "Mozambique", "22" = "Namibia", "23" = "Niger", 
#          "24" = "Nigeria", "25" = "São Tomé and Príncipe", "26" = "Senegal", "27" = "Sierra Leone", 
#          "28" = "South Africa", "29" = "Sudan", "30" = "Swaziland", "31" = "Tanzania", "32" = "Togo", 
#          "33" = "Tunisia", "34" = "Uganda", "35" = "Zambia", "36" = "Zimbabwe", "37" = "Gambia", 
#          "38" = "Angola", "39" = "Ethiopia", "40" = "Mauritania", "41" = "Seychelles", 
#          "42" = "Congo-Brazzaville"),
#   R5 = c("2" = "Benin", "3" = "Botswana", "4" = "Burkina Faso", "6" = "Cameroon", "7" = "Cabo Verde", 
#          "8" = "Côte d'Ivoire", "11" = "Ghana", "12" = "Guinea", "13" = "Kenya", "14" = "Lesotho", 
#          "15" = "Liberia", "16" = "Madagascar", "17" = "Malawi", "18" = "Mali", "19" = "Mauritius", 
#          "20" = "Morocco", "21" = "Mozambique", "22" = "Namibia", "23" = "Niger", "24" = "Nigeria", 
#          "25" = "Senegal", "26" = "Sierra Leone", "27" = "South Africa", "28" = "Sudan", 
#          "29" = "Swaziland", "30" = "Tanzania", "31" = "Togo", "32" = "Tunisia", "33" = "Uganda", 
#          "34" = "Zambia", "35" = "Zimbabwe", "36" = "Gabon", "37" = "Gambia", "38" = "São Tomé and Príncipe", 
#          "39" = "Angola", "40" = "Ethiopia", "41" = "Mauritania", "42" = "Seychelles", 
#          "43" = "Congo-Brazzaville"),
#   R4 = c("1" = "Benin", "2" = "Botswana", "3" = "Burkina Faso", "4" = "Cape Verde", "5" = "Ghana", 
#          "6" = "Kenya", "7" = "Lesotho", "8" = "Liberia", "9" = "Madagascar", "10" = "Malawi", 
#          "11" = "Mali", "12" = "Mozambique", "13" = "Namibia", "14" = "Nigeria", "15" = "Senegal", 
#          "16" = "South Africa", "17" = "Tanzania", "18" = "Uganda", "19" = "Zambia", "20" = "Zimbabwe"),
#   R3 = c("1" = "Benin", "2" = "Botswana", "3" = "Cape Verde", "4" = "Ghana", "5" = "Kenya", 
#          "6" = "Lesotho", "7" = "Madagascar", "8" = "Malawi", "9" = "Mali", "10" = "Mozambique", 
#          "11" = "Namibia", "12" = "Nigeria", "13" = "Senegal", "14" = "South Africa", 
#          "15" = "Tanzania", "16" = "Uganda", "17" = "Zambia", "18" = "Zimbabwe"),
#   R2 = c("1" = "Botswana", "2" = "Ghana", "3" = "Lesotho", "4" = "Malawi", "5" = "Mali", 
#          "6" = "Namibia", "7" = "Nigeria", "8" = "South Africa", "9" = "Tanzania", 
#          "10" = "Uganda", "11" = "Zambia", "12" = "Zimbabwe", "13" = "Cape Verde", 
#          "14" = "Kenya", "15" = "Mozambique", "16" = "Senegal"),
#   R1 = c("1" = "Botswana", "2" = "Ghana", "3" = "Lesotho", "4" = "Malawi", "5" = "Mali", 
#          "6" = "Namibia", "7" = "Nigeria", "8" = "South Africa", "9" = "Tanzania", 
#          "10" = "Uganda", "11" = "Zambia", "12" = "Zimbabwe")
# )
# 
# # Replace country codes with country names
# afro_list <- lapply(names(afro_list), function(name) {
#   # Get the corresponding table and country mapping
#   table <- afro_list[[name]]
#   mapping <- country_mapping[[name]]
#   
#   # Check for the COUNTRY or country column and replace codes
#   if (!is.null(mapping)) {
#     if ("COUNTRY" %in% names(table)) {
#       table$COUNTRY <- mapping[as.character(table$COUNTRY)]
#     } else if ("country" %in% names(table)) {
#       table$country <- mapping[as.character(table$country)]
#     }
#   }
#   
#   # Return the updated table
#   return(table)
# })
# # Rename the list with the original names
# names(afro_list) <- names(country_mapping)
# 
# # Extract only the year from the DATEINTR column
# afro_list$R9$DATEINTR <- substr(afro_list$R9$DATEINTR, 1, 4)
# 
# relevant_questions <- c(Q9A, Q9B, Q9C, Q12A, Q12B, Q14A, Q14C, Q30, Q31, Q33B, Q37A, Q37B, Q37C, Q37D, Q37E, Q37F, # Democracy: 
#                         Q10C, Q44C, # Protest: 
#                         Q33A, Q33C, # Within regime stability: 
#                         Q46M, # Violence: 
#                         Q84B, Q86F) # Ethnic Violence: 
# 
# # Load to read labels
# library(labelled)
# 
# # Function to search for a partial label in the list
# find_partial_labels <- function(data_list, search_text) {
#   results <- list()
#   for (list_name in names(data_list)) {
#     survey <- data_list[[list_name]]
#     for (var_name in names(survey)) {
#       var_label <- var_label(survey[[var_name]])
#       if (!is.null(var_label) && grepl(search_text, var_label, ignore.case = TRUE)) {
#         results <- append(results, list(list(list_name = list_name, var_name = var_name, label = var_label)))
#       }
#     }
#   }
#   return(results)
# }
# 
# # Search for the partial label
# search_text <- c("Freedom to say what you think","Freedom to join any political organization",
# "Freedom to choose who to vote for","Elections ensure MPs reflect views of voters",
# "Elections ensure voters remove unrepresentative leaders","Freeness and fairness of the last national election",
# "Last national election: fear political intimidation or violence","Extent of democracy",
# "Satisfaction with democracy","How often president ignores laws",
# "Trust president","Trust parliament/national assembly","Trust national electoral commission",
# "Trust your elected local government council","Trust the ruling party",
# "Trust opposition political parties","Attend a demonstration or protest march",
# "How often: police use excessive force during protests","How often party competition leads to conflict",
# "How often president ignores parliament","Handling preventing or resolving violent conflict",
# "Ethnic group treated unfairly by government","Trust people from other ethnic groups")
# 
# result <- list()
# for (x in search_text){
# result[[x]] <- find_partial_labels(afro_list, search_text)
# }
# 
# ## Conclusion: I stop here using Afrobarometer, as it seems that the questionaire is not consistent over the different surveys. 
# ## An intertemporal analysis does not make a lot of sense with this dataset.


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

# Checked countries:
#contains: Chad, Burkina Faso, D.R. Congo, Ghana, Mauritania, Niger, (Nigeria), Senegal, Togo, Mali
#does not contain: Benin, Central African Republic, Gabon, Equatorial Guinea, Cote d'Ivoire, Guinea-Bissau, Cameroon
# Characteristics: Monthly binary data
# 1986-2022

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

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Center for Systemic Peace, Coups d'Etat, 1946-2021", "CSPCoupsListv2021.xls")

# Read the Excel file
df.csp_coup_data.in <- read_excel(file_path)

# Combine day, month, and year into a single date column
df.csp_coup_data_long <- df.csp_coup_data.in %>%
  mutate( day = if_else(is.na(day), "01", as.character(day)), # Replace missing day with "01"
          mth = if_else(is.na(mth), "12", as.character(mth)),        # Replace missing month with "12"
    date = paste(day, mth, year, sep = "-"),
    date = as.Date(date, format = "%d-%m-%Y")
  ) %>%
  select(country, scode, date, success, arc)

df.csp_coup_data_long <- df.csp_coup_data_long%>%
  correct_identifier("scode", "country") %>%
  filter(country %in% country_to_region$country_name) %>%
  select(country, date, success)


df.csp_coup_data_long <- df.csp_coup_data_long %>%
 group_by(country) %>%                                              # Group by country
  complete(date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month"))%>%           # Replace NA with 0 for event_count
  filter(date >= as.Date("1990-01-01")) %>% # Fill missing dates
  mutate(success = replace_na(success, 0)) %>%           # Replace NA with 0 for event_count
  arrange(country, date) %>%
  rename(count = success) %>%
  mutate(event_type = "Coups")

csp_coup_plot <- ggplot(df.csp_coup_data_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Event by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "csp_coup_plot.pdf"), plot = csp_coup_plot, width = 14, height = 10)


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
  mutate(event_type = " Annual Coups")

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


# Center for Systemic Peace, High Casualty Terrorist Bombings (HCT --------
# Annual data, contains only Burkia Faso, Cameroon, Chad, Mali, Niger

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Center for Systemic Peace, High Casualty Terrorist Bombings (HCTB)", "HCTBSep2021list.xls")

# Read the Excel file
df.csp_terror_data.in <- read_excel(file_path)

# Combine day, month, and year into a single date column
df.csp_terror_data_long <- df.csp_terror_data.in %>%
  mutate(
    date = as.Date(paste(DAY, MONTH, YEAR, sep = "-"), format = "%d-%m-%Y")) %>%
    correct_identifier("LOC") %>%
  filter(LOC %in% country_to_region$country_code) %>%
  left_join(country_to_region, by = c("LOC" = "country_code")) %>%
  select(date, country_name, DEATH) %>%
  rename(country = country_name)


df.csp_terror_data_long <- df.csp_terror_data_long %>%
  group_by(country) %>%                                                                 # Group by country
  complete(date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month")) %>%  # Replace NA with 0 for event_count
  mutate(across(where(is.double), ~ replace_na(.x, 0))) %>% 
  filter(date >= as.Date("1990-01-01")) %>%                                             # Fill missing dates
  arrange(country, date) %>%                                                              # Ensure correct ordering by country and date
  rename(count = DEATH) %>%
  mutate(event_type = "Terror Attack")

csp_terror_plot <- ggplot(df.csp_terror_data_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Deaths due to Terror Attacks by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "csp_terror_plot.pdf"), plot = csp_terror_plot, width = 14, height = 10)


# Major Episodes of Political Violence, 1946-2018 (War List) --------------

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Major Episodes of Political Violence, 1946-2018 (War List)", "MEPVv2018.xls")

# Read the Excel file
df.csp_violence_data.in <- read_excel(file_path)

df.csp_violence_data <- df.csp_violence_data.in %>%
  correct_identifier("scode", "country") %>%
  mutate(date = as.Date(paste0(year, "-01-01"))) %>%         # Convert year to a Date (YYYY-01-01)
  filter(country %in% country_to_region$country_name) %>%
  select(country, date, intviol, intwar, civviol, civwar, ethviol, ethwar, civtot, inttot, actotal) %>% 
  mutate(across(everything(), ~ replace_na(.x, 0)))


df.csp_violence_data <- df.csp_violence_data %>%
  group_by(country) %>%                                                                 # Group by country
  complete(date = seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month")) %>%  # Replace NA with 0 for event_count
  mutate(across(where(is.double), ~ replace_na(.x, 0))) %>% 
  filter(date >= as.Date("1990-01-01")) %>%                                             # Fill missing dates
  arrange(country, date)                                                                # Ensure correct ordering by country and date

df.csp_violence_data_long <- df.csp_violence_data %>%
  pivot_longer(cols = intviol:actotal,  # Select all event columns
               names_to = "event_type",  # New column for event types
               values_to = "count"       # New column for values
  )# %>%
  #filter(event_type == "total_sum")

csp_violence_plot <- ggplot(df.csp_violence_data_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Event by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "csp_violence_plot.pdf"), plot = csp_violence_plot, width = 14, height = 10)



# PITF - STATE FAILURE PROBLEM SET ----------------------------------------
#Internal Wars and Failures of Governance, 1955-2018
#Political Instability (formerly, State Failure) Task Force (PITF)

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Political Instability Task Force (PITF)", "PITF Adverse Regime Change 2018.xls")

# Read the Excel file
df.csp_regime_data.in <- read_excel(file_path)

df.csp_regime_data_period <- df.csp_regime_data.in %>%
  correct_identifier("SCODE", "COUNTRY") %>%
  filter(COUNTRY %in% country_to_region$country_name) %>%
  mutate(BEGIN_DATE = ymd(paste(YRBEGIN, MOBEGIN, "01", sep = "-")),
       END_DATE = ymd(paste(YREND, MOEND, "01", sep = "-")) ) %>%
  select(-YEAR, -CCODE, -YRBEGIN, -MOBEGIN, -YREND, -MOEND, -POLITYX, -DESC, -DESC2) %>%
  distinct(BEGIN_DATE, END_DATE, COUNTRY) %>%
  rename(begin_date = BEGIN_DATE, end_date = END_DATE, country = COUNTRY) %>%
  mutate(event_type = "Regime Change")

csp_regime_plot <- ggplot(df.csp_regime_data_period, aes(xmin = begin_date, xmax = end_date, ymin = 0, ymax = 1)) +
  geom_rect(fill = "grey", color = "black", alpha = 0.5) +
  facet_wrap(~ country) +
  labs(
    title = "Regime Periods by Country",
    x = "Date",
    y = "Country"
  ) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

ggsave(file.path(benchmark_figure_dir, "csp_regime_plot.pdf"), plot = csp_regime_plot, width = 14, height = 10)


## Ethnic War

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Political Instability Task Force (PITF)", "PITF Ethnic War 2018.xls")

# Read the Excel file
df.csp_ethnic_data.in <- read_excel(file_path)

df.csp_ethnic_data_period <- df.csp_ethnic_data.in %>%
  correct_identifier("SCODE", "COUNTRY") %>%
  filter(COUNTRY %in% country_to_region$country_name) %>%
  mutate( # Central african republic ethnic war has not ended yet
    MOEND = ifelse(MOEND == 99, 9, MOEND),
    YREND = ifelse(YREND == 9999, 2024, YREND)
  ) %>%
  mutate(BEGIN_DATE = ymd(paste(YRBEGIN, MOBEGIN, "01", sep = "-")),
         END_DATE = ymd(paste(YREND, MOEND, "01", sep = "-")) ) %>%
  select(-YEAR, -CCODE, -YRBEGIN, -MOBEGIN, -YREND, -MOEND, -DESC, -DESC2) %>%
  distinct(BEGIN_DATE, END_DATE, COUNTRY) %>%
  rename(begin_date = BEGIN_DATE, end_date = END_DATE, country = COUNTRY) %>%
  mutate(event_type = "Ethnic War")


csp_ethnic_plot <- ggplot(df.csp_ethnic_data_period, aes(xmin = begin_date, xmax = end_date, ymin = 0, ymax = 1)) +
  geom_rect(fill = "grey", color = "black", alpha = 0.5) +
  facet_wrap(~ country) +
  labs(
    title = "Ethnic War Periods by Country",
    x = "Date",
    y = "Country"
  ) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

ggsave(file.path(benchmark_figure_dir, "csp_ethnic_plot.pdf"), plot = csp_ethnic_plot, width = 14, height = 10)


## Genocide

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Political Instability Task Force (PITF)", "PITF GenoPoliticide 2018.xls")

# Read the Excel file
df.csp_genocide_data.in <- read_excel(file_path)

df.csp_genocide_data_period <- df.csp_genocide_data.in %>%
  correct_identifier("SCODE", "COUNTRY") %>%
  filter(COUNTRY %in% country_to_region$country_name) %>%
  mutate( # Central african republic genocide has not ended yet
    MOEND = ifelse(MOEND == 99, 9, MOEND),
    YREND = ifelse(YREND == 9999, 2024, YREND)
  ) %>%
  mutate(BEGIN_DATE = ymd(paste(YRBEGIN, MOBEGIN, "01", sep = "-")),
         END_DATE = ymd(paste(YREND, MOEND, "01", sep = "-")) ) %>%
  select(-YEAR, -CCODE, -YRBEGIN, -MOBEGIN, -YREND, -MOEND, -DESC, -DESC2) %>%
  distinct(BEGIN_DATE, END_DATE, COUNTRY) %>%
  rename(begin_date = BEGIN_DATE, end_date = END_DATE, country = COUNTRY) %>%
  mutate(event_type = "Genocide")

csp_genocide_plot <- ggplot(df.csp_genocide_data_period, aes(xmin = begin_date, xmax = end_date, ymin = 0, ymax = 1)) +
  geom_rect(fill = "grey", color = "black", alpha = 0.5) +
  facet_wrap(~ country) +
  labs(
    title = "Genocide Periods by Country",
    x = "Date",
    y = "Country"
  ) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

ggsave(file.path(benchmark_figure_dir, "csp_genocide_plot.pdf"), plot = csp_genocide_plot, width = 14, height = 10)



## Revolution

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "Political Instability Task Force (PITF)", "PITF Revolutionary War 2018.xls")

# Read the Excel file
df.csp_revolution_data.in <- read_excel(file_path)

df.csp_revolution_data_period <- df.csp_revolution_data.in %>%
  correct_identifier("SCODE", "COUNTRY") %>%
  filter(COUNTRY %in% country_to_region$country_name) %>%
  mutate( # Mali revolution has not ended yet
    MOEND = ifelse(MOEND == 99, 9, MOEND),
    YREND = ifelse(YREND == 9999, 2024, YREND)
  ) %>%
  mutate(BEGIN_DATE = ymd(paste(YRBEGIN, MOBEGIN, "01", sep = "-")),
         END_DATE = ymd(paste(YREND, MOEND, "01", sep = "-")) ) %>%
  select(-YEAR, -CCODE, -YRBEGIN, -MOBEGIN, -YREND, -MOEND, -DESC, -DESC2) %>%
  distinct(BEGIN_DATE, END_DATE, COUNTRY) %>%
  rename(begin_date = BEGIN_DATE, end_date = END_DATE, country = COUNTRY) %>%
  mutate(event_type = "Revolution")

csp_revolution_plot <- ggplot(df.csp_revolution_data_period, aes(xmin = begin_date, xmax = end_date, ymin = 0, ymax = 1)) +
  geom_rect(fill = "grey", color = "black", alpha = 0.5) +
  facet_wrap(~ country) +
  labs(
    title = "Revolution Periods by Country",
    x = "Date",
    y = "Country"
  ) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

ggsave(file.path(benchmark_figure_dir, "csp_revolution_plot.pdf"), plot = csp_revolution_plot, width = 14, height = 10)



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


# STATE FRAGILITY INDEX AND MATRIX 2018 -----------------------------------

# Define the file path (update this to your actual file path)
file_path <- benchmark_file("CSP Database", "State Fragility Index and Matrix 2018", "SFIv2018.xls")

# Read the Excel file
df.csp_fragility_data.in <- read_excel(file_path)

df.csp_fragility_data_long <- df.csp_fragility_data.in %>%
  correct_identifier("scode", "country") %>%
  filter(country %in% country_to_region$country_name) %>%
  select(country, year, sfi) %>%
  rename(date = year, count = sfi) %>%
  mutate(event_type = "State Fragility") %>%
  mutate(date = as.Date(date))

csp_fragility_plot <- ggplot(df.csp_fragility_data_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Index by Country",
       x = "Date",
       y = "Index") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "csp_fragility_plot.pdf"), plot = csp_fragility_plot, width = 14, height = 10)


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



# GDELT -------------------------------------------------------------------
# Daily news data 1979-2014

# Read excel file from Barret for counts
df.gdelt.in <- read_excel(benchmark_file("GDELT", "Barret Replication Code GDELT", "gdelt_bycountry.xls")) %>% 
  as.tibble()
# Read csv file from Barret for normalization
df.norm.in <- read_csv(benchmark_file("GDELT", "Barret Replication Code GDELT", "monthly_country.csv"), 
                       col_names = c('MonthYear', 'ActionGeo_CountryCode', 'norm' ) )

# Prepare data table according to Barret (normalization)
df.norm <- df.norm.in %>%
  mutate( cty = countrycode(ActionGeo_CountryCode, 'fips', 'iso3c'),
          Date = as.Date( paste0(MonthYear,'01'), '%Y%m%d' ) )

df.gdelt <- df.gdelt.in %>%
  rename( cty=`Country Code`, gdelt.events=`Number of events`, 
          gdelt.articles=`Number of articles` ) %>%
  mutate(Date=as.Date(Date) ) %>%
  left_join( df.norm %>% select( cty, Date, norm ) ) %>%
  mutate( gdelt.events.norm = gdelt.events / norm,
          gdelt.articles.norm = gdelt.articles / norm ) %>%
  group_by(cty, Country) %>%
  complete( Date=seq.Date(from = as.Date('1979-01-01'), to=as.Date('2014-01-01'), by = 'month') ) %>%
  ungroup() %>%
  filter(!is.na(cty)) %>%
  replace( is.na(.), 0 ) %>%
  select( cty, Country, Date, everything() ) %>%
  arrange(cty, Date)

# Filter for country code
df.gdelt <- df.gdelt %>%
  correct_identifier("cty", "Country") %>%
  filter(Country %in% country_to_region$country_name)

# Transform wide to long table
df.gdelt_long <- df.gdelt %>%
  select(-cty) %>%
  pivot_longer(
    cols = -c(Country, Date),
    names_to = "event_type",
    values_to = "count"
  ) %>%
  rename(country = Country, date = Date) %>%
  filter(event_type %in% c("gdelt.articles.norm", "gdelt.events.norm")) %>%
  filter(date >= "1990-01-01")

df.gdelt_events_long <- df.gdelt_long %>%
  filter(event_type == "gdelt.events.norm") %>%
  mutate(event_type == "Events Normalized")

df.gdelt_articles_long <- df.gdelt_long %>%
  filter(event_type == "gdelt.articles.norm") %>%
  mutate(event_type == "Articles Normalized")


## File from GDELT website. File is too big. Couldn't push it to repository.
# df.gdelt_all.in <- read.table(paste0(wd,"/Data/benchmark data/GDELT/GDELT.MASTERREDUCEDV2.1979-2013/GDELT.MASTERREDUCEDV2.TXT"), sep = "\t", header = TRUE, fill = TRUE)
# df.gdelt_all <- df.gdelt_all.in %>%
#   select(Date, Target, NumEvents, NumArts) %>%
#   filter(Target %in% country_codes) %>%
#   mutate(Date = as.Date(as.character(Date), format = "%Y%m%d")) %>%
#   group_by(Date, Target) %>%
#   summarise_all( sum, na.rm=TRUE )

gdelt_events_plot <- ggplot(df.gdelt_events_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Events by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "gdelt_events_plot.pdf"), plot = gdelt_events_plot, width = 14, height = 10)

gdelt_articles_plot <- ggplot(df.gdelt_articles_long, aes(x = date, y = count, color = event_type)) +
  geom_line() +
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Counts by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "gdelt_articles_plot.pdf"), plot = gdelt_articles_plot, width = 14, height = 10)


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


# UCDP dataset armed conflict ---------------------------------------------
# A conflict-year dataset with information on armed conflict where at least one party is the government of a state in the time period 1946-2023.
# Missing: Equatoral Guinea

## Armed Conflict Dataset
df.ucdp_prio.in <- read_excel(benchmark_file("UCDP dataset", "UCDPPRIO Armed Conflict Dataset version 241", "UcdpPrioConflict_v24_1.xlsx"))
#my_data <- readRDS(paste0(wd,"/Data/benchmark data/UCDP dataset/UCDPPRIO Armed Conflict Dataset version 241/ucdp-prio-acd-241.rds"))


# Select time span of armed conflict periods
df.ucdp_prio_period <- df.ucdp_prio.in %>%
  correct_identifier(country_name_col = "location") %>%
  # Select relevant columns
  select(location, start_date2, ep_end, ep_end_date) %>%
  separate_rows(location, sep = ",") %>%
  # Filter rows where location partially matches any string in country_to_region$country_name
  rowwise() %>%
  filter(any(str_detect(location, country_to_region$country_name))) %>%
  # Replace location with the exact match from country_to_region$country_name
  mutate(location = country_to_region$country_name[which.max(str_detect(location, country_to_region$country_name))]) %>%
  ungroup() %>%
  filter(ep_end == 1) %>% 
  select(-ep_end) %>%
  rename(country = location, begin_date = start_date2, end_date = ep_end_date) %>%
  # Convert to proper Date format instead of character
  mutate(
    begin_date = ymd(begin_date),
    end_date = ymd(end_date)
  ) %>%
  filter(begin_date >= as.Date("1990-01-01")) %>%
  mutate(event_type = "Armed Conflicts")


ucdp_prio_plot <- ggplot(df.ucdp_prio_period, aes(xmin = begin_date, xmax = end_date, ymin = 0, ymax = 1)) +
  geom_rect(fill = "grey", color = "black", alpha = 0.5) +
  facet_wrap(~ country) +
  labs(
    title = "Armed Conflict Periods by Country",
    x = "Date",
    y = "Country"
  ) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

ggsave(file.path(benchmark_figure_dir, "ucdp_prio_plot.pdf"), plot = ucdp_prio_plot, width = 14, height = 10)


## Georeferenced Event Dataset
# Gabon, Equatorial Guinea is missing

# Load data from rds
df.ucdp_ged.in <- readRDS(benchmark_file("UCDP dataset", "UCDP Georeferenced Event Dataset (GED) Global version 241", "ged241.rds"))

df.ucdp_ged_period <- df.ucdp_ged.in %>%
  correct_identifier(country_name_col = "country") %>%
  select(country, date_start, date_end, best) %>%
  filter(country %in% country_to_region$country_name) %>%
  mutate(begin_date = as.Date(date_start),end_date = as.Date(date_end)) %>%
  filter(begin_date >= "1990-01-01") %>%
  rename(count = best) %>%
  mutate(event_type = "Violence") %>%
  select(-count, -date_start, -date_end)

ucdp_ged_plot <- ggplot(df.ucdp_ged_period, aes(xmin = begin_date, xmax = end_date, ymin = 0, ymax = 1)) +
  geom_rect(fill = "grey", color = "grey", alpha = 0.5) +
  facet_wrap(~ country) +
  labs(
    title = "Event Periods by Country",
    x = "Date",
    y = "Value"
  ) +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

ggsave(file.path(benchmark_figure_dir, "ucdp_ged_plot.pdf"), plot = ucdp_ged_plot, width = 14, height = 10)


## Political Protest

# Not enough datapoint to use!

# df.ucdp_vpp.in <- read_excel(paste0(wd,"/Data/benchmark data/UCDP dataset/UCDP Violent Political Protest Dataset version 201/UCDP_VPP_Dataset_v20_1.xlsx"))
# 
# df.ucdp_vpp_period <- df.ucdp_vpp.in %>%
#   select(Location, Year, Intensity) %>%
#     correct_identifier(country_name_col = "Location") %>%
#   filter(Location %in% country_to_region$country_name) %>%
#   rename(country = Location, date = Year)
#   
# df.ucdp_vpp_period <- df.ucdp_vpp_period %>%
#   group_by(country) %>% # Group by country
#   mutate(date = as.Date(paste0(date, "-01-01"))) %>% 
#   filter(date >= as.Date("1990-01-01")) %>%                                             # Fill missing dates
#   arrange(country, date)                                                                # Ensure correct ordering by country and date
# 
# ucdp_vpp_plot <- ggplot(df.ucdp_vpp_period, aes(x = date, y = Intensity)) +
#   geom_line() +  # Create a line plot
#   facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
#   labs(title = "Event by Country",
#        x = "Date",
#        y = "Count") +
#   theme_minimal() +
#   theme(legend.position = "bottom") +
#   scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0
# 
# ggsave(file.path(benchmark_figure_dir, "ucdp_vpp_plot.pdf"), plot = ucdp_vpp_plot, width = 14, height = 10)


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

# World Uncertainty Index -------------------------------------------------
# Quarterly frequency

# Annual World Index
#df.wui.in <- read_excel(paste0(wd,"/Data/benchmark data/World Uncertainty Index/visualizer#1292.xlsx"), skip = 1)

# Quarterly Country 3-month rolling mean Index
df.wui_q.in <- read_excel(benchmark_file("World Uncertainty Index", "WUI_Data.xlsx"), sheet = "T6")

# Missing: Equatorial Guinea

# Convert the wide table to a long table
df.wui_q_long <- df.wui_q.in %>%
  pivot_longer(
    cols = -year,                  # Keep 'year' as is, pivot other columns
    names_to = "country",          # New column for country names
    values_to = "count"            # New column for values (index)
  )

# Ensure the 'year' column is treated as a date or keep it as character
# If the year is in "YYYYqQ" format (e.g., "1952q1"), you can parse it
df.wui_q_long <- df.wui_q_long %>%
  mutate(year = as.Date(paste0(substr(year, 1, 4), "-", 
                               case_when(
                                 substr(year, 6, 6) == "1" ~ "01-01", # Q1
                                 substr(year, 6, 6) == "2" ~ "04-01", # Q2
                                 substr(year, 6, 6) == "3" ~ "07-01", # Q3
                                 substr(year, 6, 6) == "4" ~ "10-01"  # Q4
                               )
  ), format = "%Y-%m-%d")) %>%
  correct_identifier(country_code_col = "country") %>%
  filter(country %in% country_codes) %>%
  left_join(country_to_region, by = c("country" = "country_code")) %>%
  select(-region, -country) %>%
  rename(date = year, country = country_name) %>%
  filter(date >= as.Date("1990-01-01")) %>%
  mutate(event_type = "Uncertainty Index")
  
wui_q_plot <- ggplot(df.wui_q_long, aes(x = date, y = count)) +
  geom_line() +  # Create a line plot
  facet_wrap(~ country, scales = "free_y") +  # Create facets for each list_element
  labs(title = "Index by Country",
       x = "Date",
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom") #+
#scale_y_continuous(expand = expansion(mult = c(0, 0.05))) # Ensure y-axis starts at 0

ggsave(file.path(benchmark_figure_dir, "wui_q_plot.pdf"), plot = wui_q_plot, width = 14, height = 10)


## Do not use because only relevant available country in monthly frequency is Ghana
# # Monthly Country Index
# df.wui_m.in <- read_excel(paste0(wd,"/Data/benchmark data/World Uncertainty Index/WUI_M_dataset_2024_12.xlsx"), sheet = "T1")
# 
# # Convert the wide table to a long table
# df.wui_m_long <- df.wui_m.in %>%
#   pivot_longer(
#     cols = -date,                  # Keep 'year' as is, pivot other columns
#     names_to = "country",          # New column for country names
#     values_to = "index"            # New column for values (index)
#   ) %>%
#   correct_identifier(country_code_col = "country") %>%
#   filter(country %in% country_codes)


# Save Data ---------------------------------------------------------------

# Create a list containing all the data frames
benchmark_data_list <- list(
  df.acled_long = df.acled_long,
  barret_event_data_long = barret_event_data_long,
  df.cnts_long_monthly = df.cnts_long_monthly,
  df.csp_coup_data_long = df.csp_coup_data_long,
  df.csp_coup_ann_data_long = df.csp_coup_ann_data_long,
  df.csp_terror_data_long = df.csp_terror_data_long,
  df.csp_violence_data_long = df.csp_violence_data_long,
  df.csp_regime_data_period = df.csp_regime_data_period,
  df.csp_ethnic_data_period = df.csp_ethnic_data_period,
  df.csp_genocide_data_period = df.csp_genocide_data_period,
  df.csp_revolution_data_period = df.csp_revolution_data_period,
  df.csp_polity_data_long = df.csp_polity_data_long,
  df.csp_fragility_data_long = df.csp_fragility_data_long,
  df.dpi_long = df.dpi_long,
  df.gallup_long = df.gallup_long,
  df.gdelt_long = df.gdelt_long,
  df.ircg.idx_long = df.ircg.idx_long,
  df.coups_long = df.coups_long,
  df.ucdp_prio_period = df.ucdp_prio_period,
  df.ucdp_ged_period = df.ucdp_ged_period,
  df.ucdp_esov_long = df.ucdp_esov_long,
  df.wwgi_long = df.wwgi_long,  
  df.whiv_long = df.whiv_long,  
  df.wui_q_long = df.wui_q_long
)

save(benchmark_data_list, file = derived_path("benchmark_data.rda"))


# Prepare benchmark data --------------------------------------------------

# Get the names of the list elements that contain "long" and "period"
long_names <- names(benchmark_data_list)[grepl("long", names(benchmark_data_list))]
period_names <- names(benchmark_data_list)[grepl("period", names(benchmark_data_list))]

# Create the long_table
benchmark_long_table <- long_names %>%
  map_dfr(~ mutate(benchmark_data_list[[.x]], source = .x))

# Create the period_table
benchmark_period_table <- period_names %>%
  map_dfr(~ mutate(benchmark_data_list[[.x]], source = .x))

# Save
save(benchmark_long_table, file = derived_path("benchmark_long_table.rda"))
save(benchmark_period_table, file = derived_path("benchmark_period_table.rda"))


