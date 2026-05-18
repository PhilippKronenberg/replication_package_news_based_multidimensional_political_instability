


# Load required libraries
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggplot2)
source(file.path("Code", "helpers.R"))
use_package_root()
output_file <- ensure_parent_dir(annex_figure_path("africa_map.pdf"))

# Get world map data at medium resolution (as an sf object)
world <- ne_countries(scale = "medium", returnclass = "sf")

# Define the lists of countries for each group

# CEMAC region
cemac <- c("Cameroon", "Central African Rep.", "Chad", 
           "Eq. Guinea", "Gabon", "Dem. Rep. Congo")

# WAEMU region
waemu <- c("Benin", "Burkina Faso", "Côte d'Ivoire", "Guinea-Bissau", 
           "Mali", "Niger", "Senegal", "Togo")

# French-speaking Sahel region
sahel <- c("Mauritania", "Nigeria", "Ghana")

# Create a union of all countries to be highlighted
 highlight_countries <- unique(c(cemac, waemu, sahel))
 
# Check which countries in the world dataset match (by the "name" column)
# (Sometimes the country names in the dataset may slightly differ.)
world$highlight <- ifelse(world$name %in% highlight_countries, "Yes", "No")

# For adding labels, extract the highlighted countries and compute their centroids
highlight_df <- world[world$highlight == "Yes", ]
# st_centroid can sometimes fail for complex geometries; if needed, consider using st_point_on_surface()
highlight_df <- st_transform(highlight_df, crs = 4326)  # Ensure a common CRS
highlight_df_centroids <- st_centroid(highlight_df)

# Plot the map with ggplot2, adding labels for highlighted countries
pp <- ggplot(data = world) +
  geom_sf(aes(fill = highlight), color = "black") +
  geom_sf_text(data = highlight_df_centroids, aes(label = name), size = 4, color = "black") +
  coord_sf(xlim = c(-20, 60), ylim = c(-40, 40)) +
  scale_fill_manual(values = c("Yes" = "tomato", "No" = "gray90")) +
  theme_minimal() +
  labs(#title = "Map of Selected Countries",
       #subtitle = "CEMAC (tomato), WAEMU (green), Sahel (blue), Ghana (purple)",
       x = "Longitude",
       y = "Latitude") +
  theme(
    axis.text.x   = element_text(size = 14),
    axis.text.y   = element_text(size = 14),
    axis.title.x  = element_text(size = 16),
    axis.title.y  = element_text(size = 16),
    strip.text    = element_text(size = 16, face = "bold"),
    legend.text   = element_text(size = 14),
    legend.title  = element_text(size = 16, face = "bold"),
    legend.position = "none")

ggsave(output_file, plot = pp, width = 14, height = 10)

