# Packages ----------------------------------------------------------------

# Every R package the replication workflow depends on. `Code/main.R` checks the
# full list once before running anything; each script additionally checks the
# subset it needs, so the scripts can also be run one by one.
replication_packages <- function() {
  c(
    "countrycode", "dplyr", "geomtextpath", "ggplot2", "ggpubr", "haven",
    "jsonlite", "lubridate", "purrr", "readr", "readxl", "rnaturalearth",
    "rnaturalearthdata", "scales", "sf", "stringr", "tidyr", "tidyverse",
    "xtable", "zoo"
  )
}

# Attach `pkgs`, installing any that are not available yet from CRAN. Set the
# environment variable NBS_INSTALL_MISSING=FALSE to skip the installation and
# get an error listing the packages to install manually instead.
ensure_packages <- function(pkgs) {
  is_available <- function(pkg) requireNamespace(pkg, quietly = TRUE)
  missing <- pkgs[!vapply(pkgs, is_available, logical(1))]

  if (length(missing) > 0) {
    install_call <- paste0(
      "install.packages(c(", paste0('"', missing, '"', collapse = ", "), "))"
    )

    if (identical(toupper(Sys.getenv("NBS_INSTALL_MISSING", "TRUE")), "FALSE")) {
      stop(
        "Missing R packages: ", paste(missing, collapse = ", "),
        "\nInstall them with: ", install_call,
        call. = FALSE
      )
    }

    message("Installing missing R packages: ", paste(missing, collapse = ", "))
    repos <- getOption("repos")
    cran <- if (!is.null(repos) && "CRAN" %in% names(repos)) repos[["CRAN"]] else NA_character_
    if (is.na(cran) || !nzchar(cran) || identical(cran, "@CRAN@")) {
      repos <- c(CRAN = "https://cloud.r-project.org")
    }
    install.packages(missing, repos = repos)

    still_missing <- missing[!vapply(missing, is_available, logical(1))]
    if (length(still_missing) > 0) {
      stop(
        "Could not install: ", paste(still_missing, collapse = ", "),
        "\nInstall them manually with: ", install_call,
        call. = FALSE
      )
    }
  }

  invisible(lapply(pkgs, library, character.only = TRUE))
}


# Paths -------------------------------------------------------------------

package_root <- function() {
  wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  if (basename(wd) == "Code") {
    return(dirname(wd))
  }
  wd
}

use_package_root <- function() {
  setwd(package_root())
  invisible(package_root())
}

package_path <- function(...) {
  file.path(package_root(), ...)
}

raw_path <- function(...) {
  file.path(package_root(), "Data", "Raw", ...)
}

non_package_path <- function(...) {
  file.path(package_root(), "..", "non_package_materials", ...)
}

first_existing_path <- function(...) {
  candidates <- unlist(list(...))
  for (candidate in candidates) {
    if (file.exists(candidate) || dir.exists(candidate)) {
      return(candidate)
    }
  }
  candidates[[1]]
}

# Like first_existing_path(), but stops with an explicit error when none of the
# candidates exist. Used for the packaged raw inputs so that a missing or
# renamed folder fails immediately instead of silently producing empty results.
require_existing_path <- function(label, ...) {
  candidates <- unlist(list(...))
  for (candidate in candidates) {
    if (file.exists(candidate) || dir.exists(candidate)) {
      return(candidate)
    }
  }
  stop(
    "Could not find ", label, ". Looked for:\n  ",
    paste(
      normalizePath(candidates, winslash = "/", mustWork = FALSE),
      collapse = "\n  "
    ),
    "\nRun the workflow from the replication package root and check that the ",
    "bundled inputs under Data/Raw/ are present.",
    call. = FALSE
  )
}

derived_path <- function(...) {
  file.path(package_root(), "Data", "Derived", ...)
}

main_output_path <- function(...) {
  file.path(package_root(), "Outputs", "Main", ...)
}

annex_output_path <- function(...) {
  file.path(package_root(), "Outputs", "Annex", "Figures", ...)
}

main_figure_path <- function(...) {
  file.path(package_root(), "Outputs", "Main", "Figures", ...)
}

annex_figure_path <- function(...) {
  file.path(package_root(), "Outputs", "Annex", "Figures", ...)
}

main_table_path <- function(...) {
  file.path(package_root(), "Outputs", "Main", "Tables", ...)
}

annex_table_path <- function(...) {
  file.path(package_root(), "Outputs", "Annex", "Tables", ...)
}

ensure_parent_dir <- function(path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  path
}
