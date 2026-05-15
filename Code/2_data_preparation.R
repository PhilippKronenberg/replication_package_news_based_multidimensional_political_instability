#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Data preparation and NBS construction
#
# Produces:
# - Data/Derived/raw_data_NBS.rda
# - Data/Derived/prepared_data_NBS.rda
# - Data/Derived/final_data_NBS.rda
# - Data/Derived/final_data_NBS.csv
# - Data/Derived/NBS_indicators.csv
# - Outputs/Main/Figures/country_normalization_reference_counts.pdf
# - Outputs/Annex/Figures/aggregate_normalization_reference_counts.pdf
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Clean Console and Environment
rm(list = ls())
cat("\014")


# Notes -------------------------------------------------------------------

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
library(readxl)
library(purrr)
library(zoo)
library(tidyr) 


# Load Functions ----------------------------------------------------------

# Load functions
source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))


# Preliminaries -----------------------------------------------------------

# Define working directory
wd <- package_root()

# Define country codes
cntr_code <- c("nigea","eqgna","niger","camer","cafr","ghana","maurtn","gabon","upvola","icst","gubi","mali","chad","togo","benin","seneg","zaire")

# Define source codes
source_code <- c("ftfta","grdn","wp","afpr","deuen","bbcmnf","cnnwr","j", "lba","inht","aprs","xnews","ajazen","voa","ec")
#  grdn = The Guardian (U.K.), wp = The Washington Post, afpr = Agence France Presse (AFP),
# deuen = Deutsche Welle (DW English), bbcmnf = BBC Monitoring Newsfile 
# j = Wall Street Journal, lba = Reuters News, aprs = Associated Press Newswires, 
# xnews = Xinhua News Agency, ajazen = Al Jazeera, voa = Voice of America Press Releases and Documents, ec = The Economist

# No access via API:
#cnnwr = CNN Wire
#ftfta = Financial Times
#inht = International New York Times


country_codes <- c("NGA", "BEN", "TCD", "CAF", "BFA", "MLI", "GAB", "MRT", "SEN", 
                   "GNQ", "COD", "CIV", "GHA", "NER", "GNB", "CMR", "TGO")

# Map country codes to their regions
country_to_region <- data.frame(
  country_code = country_codes,  # Replace 'country_codes' with your actual list of codes
  country_name = c("Nigeria", "Benin", "Chad", "Central African Republic", "Burkina Faso", "Mali", "Gabon", 
                   "Mauritania", "Senegal", "Equatorial Guinea", "DR Congo",
                   "Côte d'Ivoire", "Ghana", "Niger", "Guinea-Bissau", "Cameroon", "Togo"), 
  stringsAsFactors = FALSE
)

# Define regions
CEMAC <- c("Cameroon", "Central African Republic", "Chad", "Equatorial Guinea", "Gabon", "Democratic Republic of the Congo")
WAEMU <- c("Benin", "Burkina Faso", "Côte d'Ivoire", "Guinea-Bissau", "Mali", "Niger", "Senegal", "Togo")
WEST_SAHEL <- c("Mali", "Niger", "Burkina Faso", "Chad", "Senegal", "Mauritania", "Nigeria", "Ghana")

country_to_region$region <- sapply(country_to_region$country_name, function(country) {
  regions <- c()
  if (country %in% CEMAC) regions <- c(regions, "CEMAC")
  if (country %in% WAEMU) regions <- c(regions, "WAEMU")
  if (country %in% WEST_SAHEL) regions <- c(regions, "WEST_SAHEL")
  
  if (length(regions) == 0) return(NA)  # If no region found, return NA
  return(paste(regions, collapse = ", "))  # Combine multiple regions into a single string
})


## Define list names
#list_names <- names(data_list)
list_names <- c( "relevant_art", 
                 "relevant_art_cnt", 
                 "relevant_social_unrest", 
                 "relevant_social_unrest_cnt",
                 "relevant_political_regime", 
                 "relevant_political_regime_cnt", 
                 "all", 
                 "all_cnt", 
                 "social_unrest", 
                 "social_unrest_cnt", 
                 "political_regime", 
                 "political_regime_cnt",
                 "today", 
                 "pol_stab_cnt", 
                 "barret_civil_unrest", 
                 "Guerilla", 
                 "Revolutions", 
                 "Civil War",
                 "Internal Conflict", 
                 "Ethnic Tensions", 
                 "Assassinations", 
                 "Religious Tensions", 
                 "Riots", 
                 "Demonstrations", 
                 "Strikes", 
                 "Democracy", 
                 "Autocracy", 
                 "Regime Change")


sublist_norm_names <- c("relevant_art", "relevant_art_cnt", "all", "all_cnt", "today")
sublist_social_unrest <- c("relevant_social_unrest", "relevant_social_unrest_cnt", "social_unrest", "social_unrest_cnt")
sublist_political_regime <- c("relevant_political_regime", "relevant_political_regime_cnt", "political_regime", "political_regime_cnt")
sublist_topic_names <- c("barret_civil_unrest", "pol_stab_cnt", "Guerilla", "Revolutions", "Civil War",
                         "Internal Conflict", "Ethnic Tensions", "Assassinations", "Religious Tensions", "Riots", "Demonstrations", "Strikes", "Democracy", "Autocracy", "Regime Change")
benchmark <- c("barret_civil_unrest")

# Define factors as named vectors
political_violence <- c("Assassinations", "Guerilla", "Riots", "Revolutions", "Internal Conflict", "Civil War", "Ethnic Tensions", "Religious Tensions")
mass_civil_protest <- c("Riots", "Strikes", "Demonstrations")
instability_within_regime <- c("Democracy")
instability_of_regime <- c("Regime Change")
political_instability <- c("Assassinations", "Guerilla", "Riots", "Revolutions", "Internal Conflict", "Civil War", "Ethnic Tensions", "Religious Tensions", "Riots", "Strikes", "Demonstrations", "Democracy", "Regime Change")

# Save all metadata into a list for easier access
metadata <- list(list_names = list_names, sublist_topic_names = sublist_topic_names, 
                 sublist_norm_names = sublist_norm_names, 
                 sublist_social_unrest = sublist_social_unrest, 
                 sublist_political_regime = sublist_political_regime, 
                 CEMAC= CEMAC, WAEMU = WAEMU, WEST_SAHEL = WEST_SAHEL, 
                 country_to_region = country_to_region, country_codes = country_codes,
                 source_code = source_code, cntr_code = cntr_code, wd = wd,
                 political_violence = political_violence, mass_civil_protest = mass_civil_protest,
                 instability_within_regime = instability_within_regime, instability_of_regime = instability_of_regime, political_instability = political_instability)


# Load Data ---------------------------------------------------------------

# Load the count data
#load("Code/Rda/data_list.rda")
#load("Code/Rda/data_list_new.rda")
load(derived_path("raw_data_NBS.rda"))

# Prepare Data ----------------------------------------------------------

## Process input data
names(data_list) <- list_names

# Create new list of same dimension
data_list_long <- data_list
data_list_long <- lapply(data_list_long, function(sublist) list())

# Process the data: Extend the data with missing values such that we have a complete timeline
data_list_long <- lapply(1:28, function(ii) {
  data_list_long[[ii]]$complete_tab <- process_data_tab(data_list[[ii]]$data_tab)
  return(data_list_long[[ii]])
})
names(data_list_long) <- list_names

# Aggregate counts of same date
data_list_long <- map(data_list_long, function(sublist) {
  sublist$complete_tab <- sublist$complete_tab %>%
    #group_by(Date, Country, Source) %>%
    group_by(Date, Country) %>%
    summarise(Count = sum(Count, na.rm = TRUE)) %>%
    ungroup()
  sublist # Return the modified sublist
})

# Cut the data at 1990 (chosen as then more observations available) and end at the end of 2024
data_list_long <- lapply(data_list_long, function(element) {
  element$complete_tab <- element$complete_tab %>%
    filter(Date >= as.Date("1990-01-01")) %>%
    filter(Date <= as.Date("2024-12-01"))
  return(element)
})

# Sort data and remove leading zeros
data_list_long <- lapply(data_list_long, function(x) {
  x$complete_tab <- x$complete_tab %>%
    arrange(Country, Date) %>%
    group_by(Country) %>%
    #arrange(Country, Source, Date) %>%
    #group_by(Country, Source) %>%
    group_modify(~ remove_leading_trailing_zeros(.x)) %>%
    ungroup()
  return(x)
})

data_list_long <- lapply(data_list_long, function(x) {
  
  if (!"complete_tab" %in% names(x)) return(x)
  
  x$complete_tab <- x$complete_tab %>%
    mutate(
      Country = case_when(
        Country == "Cote d'Ivoire" ~ "Côte d'Ivoire",
        Country == "Democratic Republic of the Congo" ~ "DR Congo",
        TRUE ~ Country
      )
    )
  
  x
})


# Sum by country
aggregated_data_list_country <- lapply(data_list_long, function(x) {
  x$complete_tab %>%
    group_by(Country, Date) %>%
    summarise(Count = sum(Count, na.rm = TRUE)) %>%
    ungroup()
})

## Note: Does not work anymore as API has changed an no data of source can be extracted together with data of region
# # Sum by country and source
# aggregated_data_list_country_source <- lapply(data_list_long, function(x) {
#   x$complete_tab %>%
#     group_by(Country, Date) %>%
#     #group_by(Country, Date, Source) %>%
#     summarise(Count = sum(Count, na.rm = TRUE)) %>%
#     ungroup()
# })


# Save data ---------------------------------------------------------------

# Save the list containing all folder data into an .rda file
save(
  data_list_long,
  aggregated_data_list_country,
  metadata,
  file = ensure_parent_dir(derived_path("prepared_data_NBS.rda"))
)

## Load the count data
#load("Code/Rda/prepared_data.rda")
## Save list elements as separate objects in the global environment
#list2env(metadata, envir = .GlobalEnv)


# Define Data ------------------------------------------------------------------

#𝑥𝑖𝑡 ∶ Number of articles about social unrest in country 𝑖 at period 𝑡
#𝑦𝑖𝑡 ∶ Number of contemporary articles in country 𝑖 at period 𝑡
#𝑧𝑡 ∶ Number of contemporary articles in period 𝑡

# x: aggregated_data_sublist
# y: aggregated_data_sublist_norm

# Calculate number of articles for each topic on country level
x <- aggregated_data_sublist <- aggregated_data_list_country[sublist_topic_names]

# Calculate number of contemporary articles on country level
y <- aggregated_data_sublist_norm <- aggregated_data_list_country[sublist_norm_names]

# Calculate number of contemporary articles for selected countries in total
z <- lapply(y, function(data) {
  data %>%
    group_by(Date) %>%
    summarise(z_count = mean(Count, na.rm = TRUE))
})


# Create factors ----------------------------------------------------------

## Aggregate subtopics to main topics ("factors")

# Define factors
list_element_mapping <- list(
  political_violence,
  mass_civil_protest,
  instability_within_regime,
  instability_of_regime,
  political_instability
)
names(list_element_mapping) <- c("political_violence","mass_civil_protest","instability_within_regime","instability_of_regime", "political_instability")

# Perform selection of topics from sublists to factors
x_grouped <- list()
for (category_name in names(list_element_mapping)) {
  relevant_elements <- list_element_mapping[[category_name]]
  matching_elements <- names(x)[names(x) %in% relevant_elements]
  if (length(matching_elements) > 0) {
    combined_table <- bind_rows(x[matching_elements])
    x_grouped[[category_name]] <- combined_table
  }
}
# Perform aggregation of subtopics to factors
x_grouped <- lapply(x_grouped, function(df) {
  df %>%
    group_by(Country, Date) %>%
    summarize(Count = sum(Count, na.rm = TRUE), .groups = "drop")  # Sum counts per group
})

# Combine factors and subtopics into one list
x <- c(x, x_grouped)


# If Regional Analysis run this section for aggregation -------------------

# Aggregate by region
x_reg <- lapply(x, function(data) {
  data %>%
    # Map each country to its corresponding regions
    mutate(Country = sapply(Country, function(country) {
      regions <- c()
      if (country %in% CEMAC) regions <- c(regions, "CEMAC")
      if (country %in% WAEMU) regions <- c(regions, "WAEMU")
      if (country %in% WEST_SAHEL) regions <- c(regions, "WEST_SAHEL")
      if (length(regions) == 0) return(NA)  # If no region, return NA
      return(paste(regions, collapse = ", "))  # Combine multiple regions into a single string
    })) %>%
    # Separate rows for each region when multiple exist
    separate_rows(Country, sep = ", ") %>%
    filter(!is.na(Country)) %>%  # Remove rows where no region was assigned
    group_by(Date, Country) %>%
    summarize(Count = sum(Count, na.rm = TRUE), .groups = "drop")  # Sum by Date and Region
})

y_reg <- lapply(y, function(data) {
  data %>%
    # Map each country to its corresponding regions
    mutate(Country = sapply(Country, function(country) {
      regions <- c()
      if (country %in% CEMAC) regions <- c(regions, "CEMAC")
      if (country %in% WAEMU) regions <- c(regions, "WAEMU")
      if (country %in% WEST_SAHEL) regions <- c(regions, "WEST_SAHEL")
      if (length(regions) == 0) return(NA)  # If no region, return NA
      return(paste(regions, collapse = ", "))  # Combine multiple regions into a single string
    })) %>%
    # Separate rows for each region when multiple exist
    separate_rows(Country, sep = ", ") %>%
    filter(!is.na(Country)) %>%  # Remove rows where no region was assigned
    group_by(Date, Country) %>%
    summarize(Count = sum(Count, na.rm = TRUE), .groups = "drop")  # Sum by Date and Region
})

# Set binary indicator for regional analysis
reg <- 0 # 0/1

if(reg == 1){
  x <- x_reg
  y <- y_reg
}


# Normalization -----------------------------------------------------------

# Calculate the mean and rolling mean of x (Count) for each country
x <- lapply(x, function(data) {
  data %>%
    group_by(Country) %>%
    mutate(x_mean = mean(Count, na.rm = TRUE)) %>%
    arrange(Date) %>%
    mutate(x_roll_mean = smooth12m(Count)) %>%
    ungroup()
})

# Calculate the mean and rolling mean of z (Count)
z <- lapply(z, function(data) {
  data %>%
    mutate(z_mean = mean(z_count, na.rm = TRUE)) %>%
    arrange(Date) %>%
    mutate(z_roll_mean = smooth12m(z_count)) %>%
    ungroup()
})

# Calculate the mean and rolling mean of y (Count) for each country
y <- lapply(y, function(data) {
  data %>%
    group_by(Country) %>%
    mutate(y_mean = mean(Count, na.rm = TRUE)) %>%
    arrange(Date) %>%
    mutate(y_roll_mean = smooth12m(Count)) %>%
    ungroup()
})


## Plot total normalization

# Add list element name
combined_data_z <- bind_rows(
  lapply(names(z), function(name) {
    z[[name]] %>%
      mutate(list_element = name)
  })
)

list_elements <- c("all_cnt")

for (ii in list_elements) {
  
  filtered_z <- combined_data_z %>%
    filter(list_element == ii)
  
  z_p <- ggplot(filtered_z, aes(x = Date)) +
    geom_line(aes(y = z_count, color = "Count")) +
    geom_line(aes(y = z_roll_mean, color = "12-month Rolling mean")) +
    #facet_wrap(~ list_element, scales = "free_y") +
    labs(#title = paste("Counts over Time"),
         x = "Date", y = "Count", color = "") +
    theme_minimal() +
    scale_color_manual(values = c("Count" = "black", "12-month Rolling mean" = "red")) +
    theme(
      axis.text.x   = element_text(size = 14),
      axis.text.y   = element_text(size = 14),
      axis.title.x  = element_text(size = 16),
      axis.title.y  = element_text(size = 16),
      strip.text    = element_text(size = 16, face = "bold"),
      legend.text   = element_text(size = 14),
      legend.title  = element_text(size = 16, face = "bold"),
      legend.position = "bottom",
    )
  
  ggsave(
    ensure_parent_dir(annex_figure_path("aggregate_normalization_reference_counts.pdf")),
    plot = z_p,
    width = 14,
    height = 10
  )
}
## Conclusion: all_cnt to be used for normalization!


## Plot country/region specific normalization

if(reg == 1){
  c_names <- c("CEMAC", "WAEMU", "WEST_SAHEL")
} else {
  c_names <- unique(country_to_region$country_name)
}

# Add list element name
combined_data_y <- bind_rows(
  lapply(names(y), function(name) {
    y[[name]] %>%
      mutate(list_element = name) %>%
      filter(Country %in% c_names)
  })
)

list_elements <- c("all_cnt")

for (ii in list_elements) {
  
  filtered_y <- combined_data_y %>%
    filter(list_element == ii)
  
  y_p <- ggplot(filtered_y, aes(x = Date)) +
    geom_line(aes(y = Count, color = "Count")) +
    geom_line(aes(y = y_roll_mean, color = "12-month Rolling mean")) +
    facet_wrap(~ Country, scales = "free_y", ncol = 4) +
    labs(#title = paste("Counts over Time by Topic: ",ii),
         x = "Date", y = "Count", color = "") +
    theme_minimal() +
    scale_color_manual(values = c("Count" = "black", "12-month Rolling mean" = "red")) +
    theme(
      axis.text.x   = element_text(size = 14),
      axis.text.y   = element_text(size = 14),
      axis.title.x  = element_text(size = 16),
      axis.title.y  = element_text(size = 16),
      strip.text    = element_text(size = 16, face = "bold"),
      legend.text   = element_text(size = 14),
      legend.title  = element_text(size = 16, face = "bold"),
      legend.position = "bottom",
    )
  
  ggsave(
    ensure_parent_dir(main_figure_path("country_normalization_reference_counts.pdf")),
    plot = y_p,
    width = 14,
    height = 10
  )
}
## Conclusion: all_cnt to be used for normalization!
## It makes sense to account for country specific trends as some countries dominate and reveal more pronounced trends as others.


# Prepare NBS indicators -------------------------------------------------

# Use all_cnt for normalization
list_elements <- c("all_cnt")

# Calculate the index A by normalizing the counts for each country with the total counts of all selected countries
for (i in list_elements) {
  x <- lapply(x, function(data) {
    data %>%
      left_join(select(z[[i]], Date, z_roll_mean, z_mean), by = "Date") %>%  # Match only by Date
      mutate(!!paste0("NBS_A") := (Count / z_roll_mean) * 100 * (x_mean / z_mean)) #%>%
      #rename_with(~ paste0(., "_"), c("z_roll_mean", "z_mean"))  # Rename dynamically
    
  })
}

# Calculate the index B by normalizing the counts for each country with the total counts of each country individually
for (i in list_elements) {
  x <- lapply(x, function(data) {
    data %>%
      left_join(select(y[[i]], Date, Country, y_roll_mean), by = c("Date", "Country")) %>%  # Match only by Date
      mutate(!!paste0("NBS_B") := (Count / y_roll_mean) ) #%>%
      #rename_with(~ paste0(., "_"), c("y_roll_mean"))  # Rename dynamically
  })
}

# Add list element name
final_data_NBS <- bind_rows(
  lapply(names(x), function(name) {
    x[[name]] %>%
      mutate(list_element = name)
  })
)

final_data_NBS <- final_data_NBS %>%
  rename(country = Country, date = Date, count = Count)

save(final_data_NBS, file = ensure_parent_dir(derived_path("final_data_NBS.rda")))

write.csv(final_data_NBS, ensure_parent_dir(derived_path("final_data_NBS.csv")), row.names = FALSE)


# Save only factor data separately ----------------------------------------

## Replace here political_instability with aggregate!
factors <- c("political_instability", "political_violence", "mass_civil_protest", "instability_within_regime", "instability_of_regime")

combined_data_NBS_excel <- final_data_NBS %>%
  select(country, date, count, NBS_A, NBS_B, list_element) %>%
  filter(list_element %in% factors) %>%
  arrange(country, list_element, date)

write.csv(combined_data_NBS_excel, ensure_parent_dir(derived_path("NBS_indicators.csv")), row.names = FALSE)


