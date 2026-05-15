#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Contagion / Lead-Lag Networks for West and Central African Countries
#
# Package version: only the formal-package appendix network figures are
# generated here. Broader contagion diagnostics are preserved in
# `../non_package_materials/Code/`.
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rm(list = ls())
cat("\014")

library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(readr)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(geomtextpath)

source(file.path("Code", "helpers.R"))
use_package_root()
source(file.path("Code", "functions.R"))

load(derived_path("prepared_data_NBS.rda"))
load(derived_path("final_data_NBS.rda"))
list2env(metadata, envir = .GlobalEnv)

topic_list <- c(
  "political_violence",
  "mass_civil_protest",
  "instability_within_regime",
  "instability_of_regime"
)

max_crosscorr <- function(x, y, lag.max = 12) {
  if (all(is.na(x)) | all(is.na(y))) {
    return(data.frame(lag = NA, corr = NA))
  }
  ccf_res <- ccf(x, y, lag.max = lag.max, plot = FALSE, na.action = na.pass)
  idx <- which.max(abs(ccf_res$acf))
  data.frame(lag = ccf_res$lag[idx], corr = ccf_res$acf[idx])
}

contagion_results_list <- list()

for (topic in topic_list) {
  monthly_tab <- final_data_NBS %>%
    filter(list_element == topic) %>%
    select(Date = date, Country = country, NBS_B)

  wide_monthly <- monthly_tab %>%
    pivot_wider(names_from = Country, values_from = NBS_B)
  wide_monthly[is.na(wide_monthly)] <- 0

  countries <- setdiff(names(wide_monthly), "Date")
  pairs <- combn(countries, 2, simplify = FALSE)

  contagion_results_list[[topic]] <- purrr::map_dfr(pairs, function(p) {
    xi <- wide_monthly[[p[1]]]
    xj <- wide_monthly[[p[2]]]
    res <- max_crosscorr(xi, xj, lag.max = 12)
    tibble(
      topic = topic,
      country_i = p[1],
      country_j = p[2],
      lag = res$lag,
      corr = round(res$corr, 2)
    )
  })
}

contagion_all <- bind_rows(contagion_results_list)

build_edges <- function(df) {
  df %>%
    filter(!is.na(lag), !is.na(corr), lag != 0) %>%
    mutate(
      from = if_else(lag > 0, country_i, country_j),
      to = if_else(lag > 0, country_j, country_i),
      lag_abs = abs(lag),
      weight = abs(corr)
    ) %>%
    select(topic, from, to, lag = lag_abs, corr, weight)
}

edges_all <- build_edges(contagion_all)

country_coords <- tribble(
  ~country_name, ~lon, ~lat,
  "Benin", 2.3, 9.3,
  "Burkina Faso", -1.6, 12.3,
  "Cameroon", 12.4, 5.0,
  "Central African Republic", 20.9, 6.6,
  "Chad", 18.7, 15.4,
  "Côte d'Ivoire", -5.5, 7.5,
  "Democratic Republic of the Congo", 23.7, -2.9,
  "Equatorial Guinea", 10.5, 1.6,
  "Gabon", 11.8, -0.8,
  "Ghana", -1.2, 7.9,
  "Guinea-Bissau", -15.2, 12.0,
  "Mali", -3.0, 17.6,
  "Mauritania", -10.9, 20.3,
  "Niger", 9.4, 17.6,
  "Senegal", -14.5, 14.4,
  "Togo", 1.1, 8.5,
  "Republic of the Congo", 15.3, -0.8
)

nodes_all <- tibble(country_name = unique(c(edges_all$from, edges_all$to))) %>%
  left_join(
    country_to_region %>% select(country_name, country_code, region),
    by = "country_name"
  ) %>%
  mutate(
    country_code = if_else(is.na(country_code), country_name, country_code),
    region = if_else(is.na(region), "Unknown", region)
  ) %>%
  left_join(country_coords, by = "country_name")

plot_contagion_network <- function(topic, file_out) {
  world <- ne_countries(scale = "medium", returnclass = "sf")

  cemac <- c("Cameroon", "Central African Rep.", "Chad", "Eq. Guinea", "Gabon", "Dem. Rep. Congo")
  waemu <- c("Benin", "Burkina Faso", "Côte d'Ivoire", "Guinea-Bissau", "Mali", "Niger", "Senegal", "Togo")
  sahel <- c("Mauritania", "Nigeria", "Ghana")

  world$highlight <- ifelse(world$name %in% unique(c(cemac, waemu, sahel)), "Yes", "No")
  world <- st_transform(world, crs = 4326)

  e <- edges_all %>% filter(topic == !!topic, corr > 0)
  nodes_topic <- nodes_all %>%
    filter(country_name %in% unique(c(e$from, e$to)))

  edges_df <- e %>%
    left_join(nodes_topic %>% select(country_name, lon, lat), by = c("from" = "country_name")) %>%
    rename(x = lon, y = lat) %>%
    left_join(nodes_topic %>% select(country_name, lon, lat), by = c("to" = "country_name")) %>%
    rename(xend = lon, yend = lat) %>%
    filter(!is.na(x), !is.na(y), !is.na(xend), !is.na(yend)) %>%
    filter(!(x == xend & y == yend)) %>%
    mutate(
      lag_scaled = ifelse(!is.na(lag), 1 / (1 + lag), 1),
      xmid = (x + xend) / 2,
      ymid = (y + yend) / 2
    )

  p <- ggplot() +
    geom_sf(data = world, aes(fill = highlight), color = "gray70", size = 0.3) +
    scale_fill_manual(values = c("Yes" = "gray80", "No" = "gray95"), guide = "none") +
    coord_sf(xlim = c(-20, 30), ylim = c(-5, 25), expand = FALSE) +
    geom_curve(
      data = edges_df,
      aes(x = x, y = y, xend = xend, yend = yend, color = corr, linewidth = weight, alpha = lag_scaled),
      curvature = 0.25,
      lineend = "round",
      arrow = arrow(angle = 25, type = "closed", length = unit(3, "mm"))
    ) +
    geom_text(data = edges_df, aes(x = xmid, y = ymid, label = abs(lag)), size = 4, color = "black", vjust = -0.5) +
    geom_point(data = nodes_topic, aes(x = lon, y = lat), color = "black", fill = "white", size = 4, shape = 21) +
    geom_text(data = nodes_topic, aes(x = lon, y = lat, label = country_code), size = 5, vjust = -0.8) +
    scale_color_gradient(
      low = "#b8e186",
      high = "#006837",
      name = "Correlation strength",
      guide = guide_colorbar(barwidth = unit(20, "lines"), barheight = unit(1.2, "lines"))
    ) +
    scale_alpha_continuous(range = c(0.3, 1), guide = "none") +
    scale_linewidth(range = c(0.3, 2.5), guide = "none") +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(size = 18),
      axis.text.y = element_text(size = 18),
      axis.title.x = element_text(size = 20),
      axis.title.y = element_text(size = 20),
      strip.text = element_text(size = 18, face = "bold"),
      legend.text = element_text(size = 18),
      legend.title = element_text(size = 20, face = "bold"),
      panel.grid = element_blank()
    ) +
    labs(x = "Longitude", y = "Latitude")

  ggsave(file_out, plot = p, width = 12, height = 9)
}

for (tp in unique(edges_all$topic)) {
  plot_contagion_network(
    topic = tp,
    file_out = ensure_parent_dir(
      annex_figure_path(paste0("contagion_network_geo_", tp, ".pdf"))
    )
  )
}
