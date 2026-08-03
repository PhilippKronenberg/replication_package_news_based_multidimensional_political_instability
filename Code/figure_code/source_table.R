#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Newspaper source summary table
#
# Produces:
# - Outputs/Main/Tables/newspaper_source_summary.tex
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Clean Console and Environment
rm(list = ls())
cat("\014")


# Load Packages -----------------------------------------------------------

# Loads the packages this script needs and installs them if they are missing
source(file.path("Code", "helpers.R"))
ensure_packages(c("tidyverse", "dplyr", "xtable", "tidyr"))


# Load Functions ----------------------------------------------------------

# Load functions
use_package_root()
source(file.path("Code", "functions.R"))


# Preliminaries -----------------------------------------------------------

# Define source codes
source_code <- c("ftfta","grdn","wp","afpr","deuen","bbcmnf","cnnwr","j", "lba","inht","aprs","xnews","ajazen","voa","ec")
#  grdn = The Guardian (U.K.), wp = The Washington Post, afpr = Agence France Presse (AFP),
# deuen = Deutsche Welle (DW English), bbcmnf = BBC Monitoring Newsfile 
# j = Wall Street Journal, lba = Reuters News, aprs = Associated Press Newswires, 
# xnews = Xinhua News Agency, ajazen = Al Jazeera, voa = Voice of America Press Releases and Documents, ec = The Economist

# Define working directory
wd <- package_root()
lookup_file <- first_existing_path(
  raw_path("restricted", "factiva_lookup", "All Active FA Sources 8-22-22.CSV"),
  raw_path("restricted", "factiva_lookup", "All Active FA Sources 8-22-22.csv")
)
table_output <- ensure_parent_dir(main_table_path("newspaper_source_summary.tex"))


# Table 1: Source Summary -------------------------------------------------

# Read in source names from Factiva
source_descriptions <- read.csv(lookup_file)

# Create table with source information
source_table <- source_descriptions[, c("Source.Code..sc.","Source.Name..sn.","Language..slg.","First.Issue.Online..fio.","Frequency..frp.","Online.Availability.Target..lag.","Primary.Source.Type..psd.")]
filtered_sources <- source_table %>%
  filter(str_to_lower(Source.Code..sc.) %in% source_code) %>% select(-'Source.Code..sc.')
colnames(filtered_sources) <- c("Source","Language","First Publication","Frequency","Availability","Type")
filtered_sources$`First Publication` <- as.Date(as.character(filtered_sources$`First Publication`), format = "%Y%m%d")
filtered_sources$`First Publication` <- format(filtered_sources$`First Publication`, "%Y-%m-%d")
filtered_sources$Type <- gsub("&", "and", filtered_sources$Type)
filtered_sources$Type <- gsub("Wires: ", "", filtered_sources$Type)
filtered_sources$Type <- gsub("Print Editions: ", "", filtered_sources$Type)
filtered_sources$Availability <- gsub("publication date", "publication", filtered_sources$Availability)
filtered_sources <- filtered_sources %>%
  mutate(Source = ifelse(Source == "Voice of America Press Releases and Documents", "Voice of America", Source)) %>%
  mutate(Frequency = ifelse(Frequency == "Monday-Saturday", "Mo-Sa", Frequency))

# Convert the data frame to an xtable object
tex_table <- xtable(filtered_sources, 
                    caption = "Summary of Newspaper Sources", 
                    label = "tab:sources_summary")

# Open the file and write the LaTeX preamble with resizing commands
cat("\\begin{table}[!t]\n",
    "  \\caption{Summary of Newspaper Sources}\n",
    "  \\label{tab:sources_summary}\n",
    "  \\centering\n",
    "  \\resizebox{15cm}{!}{%\n",  # Set table width to 15cm
    file = table_output)

# Print the xtable content directly into the file
print(tex_table, 
      file = table_output, 
      include.rownames = FALSE, 
      hline.after = c(-1, 0, nrow(filtered_sources)),
      add.to.row = list(
        pos = list(-1, 0, nrow(filtered_sources)),
        command = c('\\hline \\hline \\addlinespace[0.3em]\n',
                    '\\addlinespace[0.3em]\n',
                    '\\hline \\hline\n')
      ),
      tabular.environment = "tabular",
      floating = FALSE,  # Prevents LaTeX from floating the table
      size = "scriptsize",  # Use "scriptsize" or "tiny" for smaller text
      sanitize.text.function = identity,  # Allows LaTeX commands within the table
      caption.placement = "top",
      latex.environments = "center",
      booktabs = FALSE,
      table.placement = "!t",
      append = TRUE)  # Continue writing to the same file

# Close the resizebox and the table environment
cat("  }%\n",
    "\\end{table}\n",
    file = table_output, append = TRUE)

# Append notes to the .tex file
notes <- "\\begin{minipage}{15cm}
{\\footnotesize{\\textit{Notes:} This table summarizes the various news sources, their availability, frequency, and types.}}
\\end{minipage}"

cat(notes, file = table_output, append = TRUE)

