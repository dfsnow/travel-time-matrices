library(tigris)
library(dplyr)
library(sf)
library(glue)
options(tigris_use_cache = TRUE)

counties <- read_table(
  "input/2010/county_geoids_list.txt",
  col_names = c("county")
) %>%
  pull(county)



##### Tracts #####

# Load tract locs from CSV and convert to geometry
tract_centroids <- readr::read_csv("input/2010/tract_pop_wtd_centroids.csv.bz2") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE) %>%
  mutate(county_id = substr(id, 1, 5)) %>%
  st_transform(2163)

# For each county, create origins for all tracts inside the county proper
# and destinations for all tract centroids inside the 100 km buffer
for (county in counties) {
  print(paste("Saving county number:", county))
  
  # Create dir in tract_resources/ to store OD files if not exists
  county_dir_tract <- glue("input/2010/tract_resources/{county}")
  if (!dir.exists(county_dir_tract)) dir.create(county_dir_tract)
  
  # Get all origins using FIPS codes
  tract_centroids %>%
    filter(county_id == county) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(glue("input/2010/tract_resources/{county}/origins.csv"))
 
  # Load the 100 km buffer from file 
  county_100_km_buffer <- st_read(
    glue("input/2010/county_buffers/{county}_100.geojson"),
    quiet = TRUE
  ) %>%
    mutate(buffer_county = county_id) %>%
    st_transform(2163)
  
  # Get all destinations within the 100 km buffer
  destinations <- tract_centroids %>%
    st_join(county_100_km_buffer, join = st_within) %>%
    filter(!is.na(buffer_county)) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(glue("input/2010/tract_resources/{county}/destinations.csv"))
  
}
