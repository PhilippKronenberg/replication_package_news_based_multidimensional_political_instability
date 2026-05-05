#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Newspaper Sentiment Analysis for West and Central African Countries
# Authors: Philipp Kronenberg, Pierre Jean-Claude Mandon
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Clean Console and Environment
rm(list = ls())
cat("\014")


# Notes -------------------------------------------------------------------

# Note: I had to remove the source details as the API of factiva has been changed and it is not possible anymore to extract two outputs (region codes and source code) at once.
# Thus, region and sources could not be linked anymore. Thus, I decided to drop the analysis of sources completely. 
# In case it would be necessary, I could still extract the sources but would make additional API requests necessary.

#General measure of political instability:
#0.

# Normalization series:
#1. search all contemporary articles excluding irrelevant topics
#2. search all contemporary articles for specific countries excluding irrelevant topics
#7. search all contemporary articles excluding non-articles
#8. search all contemporary articles for specific countries excluding non-articles
#13. search all contemporary articles excluding non-articles with keyword "today"

# Baseline measure
#3. search all contemporary articles excluding irrelevant topics including social unrest topics
#4. search all contemporary articles for specific countries excluding irrelevant topics including social unrest topic
#9. search all contemporary articles excluding non-articles including social unrest topics
#10. search all contemporary articles for specific countries excluding non-articles including social unrest topic

#5. search all contemporary articles excluding irrelevant topics including social political regime topic
#6. search all contemporary articles for specific countries excluding irrelevant topics including political regime topic
#11. search all contemporary articles excluding non-articles including social political regime topic
#12. search all contemporary articles for specific countries excluding non-articles including political regime topic

# Keyword measures
#14. search all contemporary articles for specific countries excluding irrelevant topics include keywords but no topics 
#15. Barrett civil unrest
#16. Guerilla
#17. Revolutions
#18. Civil War
#19. Internal Conflict
#20. Ethnic Tensions
#21. Assassinations
#22. Religious Tensions
#23. Riots
#24. Demonstrations
#25. Strikes
#26. Democracy
#27. Autocracy
#28. Regime Change

# Packages ----------------------------------------------------------------

library(jsonlite)
library(ggplot2)
library(tidyverse)
library(dplyr)
library(xtable)
library(lubridate)
library(countrycode)
library(readxl)
library(purrr)


# Preliminaries -----------------------------------------------------------

# Define working directory
source(file.path("Code", "helpers.R"))
use_package_root()
wd <- package_root()

restricted_results_root <- first_existing_path(
  package_path("Data", "Raw", "restricted", "factiva_api", "Results_new"),
  non_package_path("archive", "Code_working", "Data_download", "Results_new")
)

factiva_lookup_dir <- first_existing_path(
  package_path("Data", "Raw", "restricted", "factiva_lookup"),
  non_package_path("private_data", "Literatur", "Factiva", "Lookup Codes to Share")
)

# Define country codes
cntr_code <- c("nigea", "eqgna", "niger","camer","cafr","ghana","maurtn","gabon","upvola","icst","gubi","mali","chad","togo","benin","seneg","zaire")

# Define source codes
source_code <- c("ftfta","grdn","wp","afpr","deuen","bbcmnf","cnnwr","j","lba","inht","aprs","xnews","ajazen","voa","ec")
#  grdn = The Guardian (U.K.), wp = The Washington Post, afpr = Agence France Presse (AFP),
# deuen = Deutsche Welle (DW English), bbcmnf = BBC Monitoring Newsfile 
# j = Wall Street Journal, lba = Reuters News, aprs = Associated Press Newswires, 
# xnews = Xinhua News Agency, ajazen = Al Jazeera, voa = Voice of America Press Releases and Documents, ec = The Economist

# No access via API:
#cnnwr = CNN Wire
#ftfta = Financial Times
#inht =International New York Times


country_codes <- c("NGA", "BEN", "TCD", "CAF", "BFA", "MLI", "GAB", "MRT", "SEN", 
                   "GNQ", "COD", "CIV", "GHA", "NER", "GNB", "CMR", "TGO")


# Read the data -----------------------------------------------------------

# Initialize a list to store data for each folder
data_list <- list()

# Loop through folders numbered 1 to 28
for (folder_num in 1:28) {
  print(folder_num)
  # Define the folder path for each iteration
  json_folder <- file.path(restricted_results_root, folder_num)
  
  # Skip this iteration if the folder does not exist
  if (!dir.exists(json_folder)) {
    message(paste("Folder", json_folder, "does not exist. Skipping."))
    next
  }
  
  # Get a list of all JSON files in the folder
  json_files <- list.files(json_folder, pattern = "*.json", full.names = TRUE)
  
  # Initialize an empty list to store the data from each file
  all_data_tabs <- list()
  
  # Loop through each file, read the data, and store it in the list
  for (file in json_files) {
    # Try parsing the full file as regular JSON
    is_ndjson <- FALSE
    try_result <- try(fromJSON(file), silent = TRUE)
    
    if (inherits(try_result, "try-error")) {
      is_ndjson <- TRUE
    }
    
    if (is_ndjson) {
      # NDJSON: parse line-by-line
      json_lines <- readLines(file)
      parsed_lines <- lapply(json_lines, fromJSON)
      data_tab <- bind_rows(parsed_lines)
      data_tab$count <- as.numeric(data_tab$count)
      # # Add source_code based on filename
      # source_code <- NA
      # data_tab$source_code <- source_code
    } else {
      # Regular JSON
      data <- try_result
      if (!is.null(data$data$attributes$results)) {
        data_tab <- data$data$attributes$results
      } else {
        data_tab <- as.data.frame(data)
      }
      
      # Drop 'source_code' column if it exists
      if ("source_code" %in% names(data_tab)) {
        data_tab$source_code <- NULL
      }
      
      # Ensure 'count' is numeric for aggregation
      data_tab$count <- as.numeric(data_tab$count)
      
      # Aggregate by publication_datetime and region_codes
      data_tab <- data_tab %>%
        group_by(publication_datetime, region_codes) %>%
        summarise(count = as.numeric(sum(count, na.rm = TRUE), .groups = "drop"))
    }
    # Append to list
    all_data_tabs <- append(all_data_tabs, list(data_tab))
  }
  
  # Merge all the data tabs together into one data frame
  data_tab <- bind_rows(all_data_tabs)

  # Check if all unique entries are in "yyyy-mm-dd" format
  check <- if (all(grepl("^\\d{4}-\\d{2}-\\d{2}$", unique(data_tab$publication_datetime)))) 1 else 0
  
  if (check == 0) {
    # Format the columns if the format is not "yyyy-mm-dd"
    data_tab$count <- as.numeric(data_tab$count)
    data_tab$publication_datetime <- as.Date(paste0(data_tab$publication_datetime, "-01"), format = "%Y-%m-%d")
  } else {
    # Print message for daily data
    print("daily data: will be aggregated to monthly values")

    # Aggregate to monthly observations
    data_tab <- data_tab %>%
      mutate(publication_datetime = format(as.Date(publication_datetime), "%Y-%m-01")) %>%
      #group_by(publication_datetime, region_codes, source_code) %>%
      group_by(publication_datetime, region_codes) %>%
      summarise(count = sum(as.numeric(count), na.rm = TRUE), .groups = "drop") %>%
      ungroup()
  }

  # Read in country names from Factiva
  cntr_descriptions <- read.csv(file.path(factiva_lookup_dir, "regions.csv"))
  cntr_descriptions$cntr_code <- tolower(cntr_descriptions$code)
  
  # Read in source names from Factiva
  source_descriptions <- read.csv(
    first_existing_path(
      file.path(factiva_lookup_dir, "All Active FA Sources 8-22-22.CSV"),
      file.path(factiva_lookup_dir, "All Active FA Sources 8-22-22.csv")
    )
  )
  
  # For the folders which count total number of articles for all countries we do not filter for region_codes
  if (folder_num %in% c(1,3,5,7,9,11,13)) {
  } else {
  # Filter for countries
  data_tab <- data_tab %>%
    filter(region_codes %in% cntr_code)
  }

  # Add country names
  data_tab <- merge(data_tab, cntr_descriptions, by.x = "region_codes", by.y = "cntr_code", all.x = TRUE)
  
  # # Add source names
  # source_descriptions <- source_descriptions[, c("Source.Code..sc.", "Source.Name..sn.")]
  # data_tab <- merge(data_tab, source_descriptions, by.x = "source_code", by.y = "Source.Code..sc.", all.x = TRUE)
  
  # Rename and select relevant columns
  data_tab <- data_tab %>%
    rename(Country = description, Date = publication_datetime, Count = count) %>%
    #rename(Country = description, Date = publication_datetime, Source = Source.Name..sn., Count = count) %>%
    #select(Date, Country, Source, Count)
    select(Date, Country, Count)

  # Delete duplicate rows in case some data was collected multiple times
  # data_tab <- data_tab %>%
  #   #distinct(Date, Source, Country, .keep_all = TRUE)
  #   distinct(Date, Country, .keep_all = TRUE)

  # Save all relevant tables for this folder in a list
  folder_data <- list(data_tab = data_tab)
  
  # Append the list to the data_list list
  data_list[[paste0("folder_", folder_num)]] <- folder_data
}

# Save the list containing all folder data into an .rda file
save(
  data_list,
  file = ensure_parent_dir(derived_path("intermediate", "raw_data_NBS.rda"))
)

