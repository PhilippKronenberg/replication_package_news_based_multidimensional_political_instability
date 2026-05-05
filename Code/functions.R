
# Functions ---------------------------------------------------------------

# Define a function to process each data_tab
process_data_tab <- function(data_tab) {

  # Ensure Date is of Date type
  data_tab$Date <- as.Date(data_tab$Date)
  
  # Create a sequence of monthly dates from the min to max date in the dataset
  date_seq <- seq(min(data_tab$Date), max(data_tab$Date), by = "month")
  
  # Create a data frame with all combinations of Date, Country, and Source
  full_dates <- expand.grid(Date = date_seq, 
                            Country = unique(data_tab$Country)#,
                            #Source = unique(data_tab$Source)
                            )
  
  # Merge with the original data and fill in missing values with 0
  data_complete <- full_dates %>%
    #left_join(data_tab, by = c("Date", "Country", "Source")) %>%
    left_join(data_tab, by = c("Date", "Country")) %>%
    replace_na(list(Count = 0))
  
  return(data_complete)
}

# Function to remove leading zeros until a non-zero is encountered
remove_leading_zeros <- function(df) {
  # Find the first non-zero occurrence
  first_non_zero <- which(df$Count != 0)[1]
  
  # Keep rows starting from the first non-zero count
  if (!is.na(first_non_zero)) {
    df <- df[first_non_zero:nrow(df), ]
  }
  
  return(df)
}


remove_leading_trailing_zeros <- function(df) {
  # Find the first and last non-zero occurrence
  non_zero_indices <- which(df$Count != 0)
  
  if (length(non_zero_indices) > 0) {
    first_non_zero <- min(non_zero_indices)
    last_non_zero <- max(non_zero_indices)
    
    # Keep rows within the range of first to last non-zero counts
    df <- df[first_non_zero:last_non_zero, ]
  } else {
    # If all rows are zeros, return an empty data frame
    df <- df[0, ]
  }
  
  return(df)
}

smooth.12m <- function(x) stats::filter( x=x, filter = rep(1/12,12), sides=1 )
idx.100 <- function(x) x / mean(x,na.rm = TRUE) * 100 # how values relate to their average level
idx.sd <- function(x) ( x - mean(x,na.rm = TRUE) ) / sd(x,na.rm = TRUE) # how much values deviate from their mean
scale.0.100 <- function(x) (x-min(x,na.rm = TRUE)) / diff(range(x,na.rm = TRUE)) * 100 # need all series on the same scale
smooth12m <- function(x) {
  rollapply(x, width = 12, FUN = mean, align = "right", fill = NA, partial = TRUE)
}
smooth3m <- function(x) {
  rollapply(x, width = 3, FUN = mean, align = "right", fill = NA, partial = TRUE)
}

# Scaling function to rescale values to the range [0, 100]
index_scale <- function(x) {
  min_x <- min(x, na.rm = TRUE)
  max_x <- max(x, na.rm = TRUE)
  
  # Handle case where all values are the same (avoid division by zero)
  if (min_x == max_x) {
    return(rep(50, length(x)))  # Return 50 if there's no variation in the values
  }
  
  # Rescale x to the [0, 100] range
  scaled_x <- (x - min_x) / (max_x - min_x) * 100
  return(scaled_x)
}



# Function to check for missing months
check_missing_dates <- function(df, name, country_col = "Country", date_col = "Date") {
  message("Processing: ", name) 
  
  df <- df %>%
    mutate(Date = as.Date(Date)) %>%
    arrange(!!sym(country_col), !!sym(date_col))
  
  # Get unique country names
  #countries <- unique(df[[country_col]])
  countries <- country_to_region$country_name
  
  # Store missing data
  missing_data_list <- list()
  
  for (country in countries) {
    country_data <- df %>% filter(!!sym(country_col) == country)
    
    # Create full sequence of dates from min to max month
    full_dates <- seq(as.Date("1990-01-01"), as.Date("2024-08-01"), by = "month")
    
    # Find missing dates
    missing_dates <- as.Date(setdiff(full_dates, country_data[[date_col]]), origin = "1970-01-01")
    if (length(missing_dates) > 0) {
      missing_data_list[[country]] <- missing_dates
    }
  }
  
  return(missing_data_list)
}



## Function that corrects country name and code and make it consistent with my filter
correct_identifier <- function(data, country_code_col = NULL, country_name_col = NULL) {
  data <- data %>% ungroup() # Ensure the data is not grouped
  
  if (!is.null(country_code_col) && country_code_col %in% names(data)) {
    data <- data %>%
      mutate(
        !!country_code_col := case_when(
          .[[country_code_col]] == "CAM" ~ "CMR",
          .[[country_code_col]] == "CHA" ~ "TCD",
          .[[country_code_col]] == "GNB" ~ "GNB",
          .[[country_code_col]] == "IVO" ~ "CIV",
          .[[country_code_col]] == "MLI" ~ "MLI",
          .[[country_code_col]] == "CEN" ~ "CAF",
          .[[country_code_col]] == "EQG" ~ "GNQ",
          .[[country_code_col]] == "SEN" ~ "SEN",
          .[[country_code_col]] == "BFO" ~ "BFA",
          .[[country_code_col]] == "BEN" ~ "BEN",
          .[[country_code_col]] == "NIR" ~ "NER",
          .[[country_code_col]] == "GHA" ~ "GHA",
          .[[country_code_col]] == "MAA" ~ "MRT",
          .[[country_code_col]] == "ZAI" ~ "COD", 
          .[[country_code_col]] == "ZAR" ~ "COD",
          .[[country_code_col]] == "TGO" ~ "TGO",
          .[[country_code_col]] == "GAB" ~ "GAB",
          TRUE ~ .[[country_code_col]]  # Keep all other SCODEs unchanged
        )
      )
  }
  
  if (!is.null(country_name_col) && country_name_col %in% names(data)) {
    data <- data %>%
      mutate(
        !!country_name_col := case_when(
          .[[country_name_col]] == "Ivory Coast" ~ "Côte d'Ivoire",
          .[[country_name_col]] == "Cote d’Ivoire" ~ "Côte d'Ivoire",
          .[[country_name_col]] == "Eq. Guinea" ~ "Equatorial Guinea",
          .[[country_name_col]] == "Central African Repub" ~ "Central African Republic",
          .[[country_name_col]] == "Cent. Af. Rep." ~ "Central African Republic", 
          .[[country_name_col]] == "Guinea Bissau" ~ "Guinea-Bissau",
          .[[country_name_col]] == "Congo Kinshasa" ~ "DR Congo", 
          .[[country_name_col]] == "Congo-Kinshasa" ~ "DR Congo",
          .[[country_name_col]] == "Congo (Kinshasa)" ~ "DR Congo",
          .[[country_name_col]] == "Democratic Republic of Congo" ~ "DR Congo",
          .[[country_name_col]] == "Dem. Rep. of Congo" ~ "DR Congo", 
          .[[country_name_col]] == "DR Congo (Zaire)" ~ "DR Congo", 
          .[[country_name_col]] == "Democratic Republic of the Congo" ~ "DR Congo", 
          .[[country_name_col]] == "D.R. Congo" ~ "DR Congo", 
          .[[country_name_col]] == "Congo, DR" ~ "DR Congo",
          .[[country_name_col]] == "Congo (DRC)" ~ "DR Congo",
          .[[country_name_col]] == "Congo, Dem. Rep." ~ "DR Congo",
          TRUE ~ .[[country_name_col]]  # Keep all other values unchanged
        )
      )
  }
  
  return(data)
}


