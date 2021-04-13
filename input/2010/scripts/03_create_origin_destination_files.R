library(tigris)
library(dplyr)
library(sf)
library(glue)
options(tigris_use_cache = TRUE)

# Load continental US counties from file
county_ids <- readr::read_table(
  "input/2010/county/geoid_list.txt",
  col_names = c("county")
) %>%
  pull(county)



##### Tracts #####

# Load tract locs from CSV and convert to geometry
tract_centroids <- readr::read_csv("input/2010/tract/pop_wtd_centroids.csv.bz2") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE) %>%
  mutate(county_id = substr(id, 1, 5)) %>%
  st_transform(2163)

# For each county, create origins for all tracts inside the county proper
# and destinations for all tract centroids inside the 100 km buffer
for (county in county_ids) {
  print(paste("Saving county number:", county))
  
  # Create dir in tract/resources/ to store OD files if not exists
  county_dir_tract <- glue("input/2010/tract/resources/{county}")
  if (!dir.exists(county_dir_tract)) dir.create(county_dir_tract)
  
  # Get all origins using FIPS codes
  tract_centroids %>%
    filter(county_id == county) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(county_dir_tract, "origins.csv"))
 
  # Load the 100 km buffer from file 
  county_100_km_buffer <- st_read(
    glue("input/2010/county/buffers/{county}_100.geojson"),
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
    readr::write_csv(file.path(county_dir_tract, "destinations.csv"))
}



##### ZCTAs #####

# Load counties to perform spatial intersection on ZCTA centroids
counties_df <- counties(year = 2010) %>%
  select(county_id = GEOID10) %>%
  st_transform(2163)

# Load ZCTAs locs from CSV, convert to geometry, then join containing county
zcta_centroids <- readr::read_csv("input/2010/zcta/pop_wtd_centroids.csv.bz2") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE) %>%
  st_transform(2163) %>%
  st_join(counties_df, join = st_within)

# For ZCTAs missing a spatially joined county, I manually match them to the
# nearest/correct county
zcta_centroids <- zcta_centroids %>%
  mutate(
    county_id = case_when(
      id == "04745" ~ "23003",
      id == "55725" ~ "27137",
      id == "96769" ~ "15007",
      TRUE ~ county_id
    )
  )
  
# For each county, create origins for all ZCTAs inside the county proper
# and destinations for all ZCTA centroids inside the 100 km buffer
for (county in county_ids) {
  print(paste("Saving county number:", county))
  
  # Create dir in tract_resources/ to store OD files if not exists
  county_dir_zcta <- glue("input/2010/zcta/resources/{county}")
  if (!dir.exists(county_dir_zcta)) dir.create(county_dir_zcta)
  
  # Get all origins using FIPS codes
  zcta_centroids %>%
    filter(county_id == county) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(county_dir_zcta, "origins.csv"))
  
  # Load the 100 km buffer from file 
  county_100_km_buffer <- st_read(
    glue("input/2010/county/buffers/{county}_100.geojson"),
    quiet = TRUE
  ) %>%
    mutate(buffer_county = county_id) %>%
    st_transform(2163)
  
  # Get all destinations within the 100 km buffer
  destinations <- zcta_centroids %>%
    st_join(county_100_km_buffer, join = st_within) %>%
    filter(!is.na(buffer_county)) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(county_dir_zcta, "destinations.csv"))
  
}
