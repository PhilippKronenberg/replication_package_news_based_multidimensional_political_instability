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
