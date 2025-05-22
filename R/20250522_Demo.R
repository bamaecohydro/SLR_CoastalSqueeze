#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Title: Coastal squeeze demo
# Coder: Nate Jones (natejones@ua.edu)
# Date: 5/22/2025
# Purpose: Explore possibility of a coastal squeeze analysis in Mobile Bay
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 1: Setup workspace ------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Clear memory
remove(list = ls())

#load packages of interest
library(tidyverse)
library(purrr)
library(raster)
library(sf)
library(mapview)
library(elevatr)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 2: Gather spatial data --------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Define study location
pnt <- tibble(x = -87.825618, y = 30.350089) %>% st_as_sf(coords = c("x", "y"), crs = 4326)

#Download DEM
dem <- get_elev_raster(pnt, z = 14)

#Project DEM into UTM 16
dem <- projectRaster(dem, crs = CRS("+proj=utm +zone=16 +datum=WGS84 +units=m"))

#Plot for funzies
mapview(dem) + mapview(pnt) 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 3: Create function to identify marsh extent -----------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Create function 
SLR_fun <- function(ele_min, ele_max, SLR){

  # Create a mask for areas within the elevation band
  marsh <- (dem >= (ele_min + SLR)) & (dem <= (ele_max + SLR))
  marsh[marsh == 0] <- NA
  
  #Estimate Marsh area
  area_km2 <- cellStats(marsh, sum, na.rm=T)*res(marsh)[1]*res(marsh)[2]/1000000

  #Export results
  tibble(SLR, area_km2)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4: Apply function -------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define constants and SLR range
ele_min_constant <- 0    # your minimum elevation
ele_max_constant <- 2    # your maximum elevation
SLR_range <- seq(0, 1, by = 0.05)  # SLR from 0 to 2m in 0.1m steps

# Apply function across SLR range - map_dfr combines tibble rows
results_df <- map_dfr(SLR_range, ~SLR_fun(ele_min_constant, ele_max_constant, .x))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Step 4: Plot -----------------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
results_df %>%
  ggplot(aes(x = SLR, y = area_km2)) +
  geom_line(size = 1.2, color = 'SteelBlue3') +
  geom_point(size = 2.5, color = "SteelBlue4", alpha = 0.8) +
  labs(
    title = "Salt Marsh Area Under Sea Level Rise Scenarios",
    subtitle = paste("Mobile Bay, Alabama | Marsh elevation band:", ele_min_constant, "-", ele_max_constant, "m above MSL"),
    x = "Sea Level Rise (m)",
    y = "Available Marsh Area (km²)",
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank()
  )

ggsave("docs/demo.png", width = 4.854, height = 3, units = "in", dpi = 300)
