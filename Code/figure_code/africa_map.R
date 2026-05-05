




# Install packages if you haven't already
# install.packages(c("sf", "rnaturalearth", "rnaturalearthdata", "ggplot2"))

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
 
# # Plot the map with ggplot2.
# # We zoom in on Africa by setting appropriate coordinate limits.
# ggplot(data = world) +
#   geom_sf(aes(fill = highlight), color = "black") +
#   coord_sf(xlim = c(-20, 60), ylim = c(-40, 40)) +
#   scale_fill_manual(values = c("Yes" = "tomato", "No" = "gray90")) +
#   theme_minimal() +
#   labs(title = "African Regions: CEMAC, WAEMU, French-speaking Sahel, and Ghana",
#        subtitle = "Highlighted in red (tomato)") +
#   theme(legend.position = "none")




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



# 
# # Create subsets for each region
# world_cemac <- subset(world, name %in% cemac)
# world_waemu <- subset(world, name %in% waemu)
# world_sahel <- subset(world, name %in% sahel)
# 
# 
# # Compute centroids for labeling (using st_point_on_surface() can sometimes work better than st_centroid())
# labels_sf <- st_point_on_surface(world[world$name %in% c(cemac, waemu, sahel, ghana), ])
# 
# # Now plot using ggplot2. The order of the geom_sf() layers matters.
# ggplot() +
#   # Plot the full world (or Africa) in a light gray background
#   geom_sf(data = world, fill = "gray90", color = "black") +
#   
#   # Add Sahel region layer first (blue)
#   geom_sf(data = world_sahel, fill = "blue", color = "black", alpha = 0.7) +
#   
#   # Then add WAEMU region (green)
#   geom_sf(data = world_waemu, fill = "green", color = "black", alpha = 0.7) +
#   
#   # Then add CEMAC region (tomato)
#   geom_sf(data = world_cemac, fill = "tomato", color = "black", alpha = 0.7) +
#   
#   # Add labels for the highlighted countries with a smaller text size
#   geom_sf_text(data = labels_sf, aes(label = name), size = 2.5, color = "black") +
#   
#   # Zoom in on Africa (adjust coordinate limits as needed)
#   coord_sf(xlim = c(-20, 60), ylim = c(-40, 40)) +
#   
#   theme_minimal() +
#   labs(title = "Map of Selected Countries",
#        #subtitle = "CEMAC (tomato), WAEMU (green), Sahel (blue), Ghana (purple)",
#        x = "Longitude",
#        y = "Latitude") +
#   theme(legend.position = "none")
