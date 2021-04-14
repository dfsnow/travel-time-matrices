library(tigris)
library(dplyr)
library(sf)
library(glue)
options(tigris_use_cache = TRUE)

# Load list of US state FIPS codes, ignore territories and PR
us_states <- unique(fips_codes$state_code)[1:51]



##### Tracts #####

# Load tract locs from CSV and convert to geometry
tract_centroids <- readr::read_csv("input/2010/tract/pop_wtd_centroids.csv.bz2") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE) %>%
  mutate(state_id = substr(id, 1, 2)) %>%
  st_transform(2163)

# For each state, create origins for all tracts inside the state proper
# and destinations for all tract centroids inside the state's 100 km buffer
for (state in us_states) {
  print(paste("Saving state number:", state))
  
  # Create dir in tract/resources/ to store OD files if not exists
  state_dir_tract <- glue("input/2010/tract/origin_destination_by_state/{state}")
  if (!dir.exists(state_dir_tract)) dir.create(state_dir_tract)
  
  # Get all origins using FIPS codes
  tract_centroids %>%
    filter(state_id == state) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(state_dir_tract, "origins.csv"))
 
  # Load the 100 km buffer from file 
  state_100_km_buffer <- st_read(
    glue("input/shared/buffers/{state}.geojson"),
    quiet = TRUE
  ) %>%
    select(buffer_state = state_id) %>%
    st_transform(2163)
  
  # Get all destinations within the 100 km buffer
  destinations <- tract_centroids %>%
    st_join(state_100_km_buffer, join = st_within) %>%
    filter(!is.na(buffer_state)) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(state_dir_tract, "destinations.csv"))
}



##### ZCTAs #####

# Load states to perform spatial intersection on ZCTA centroids
states_df <- states(year = 2010) %>%
  select(state_id = GEOID10) %>%
  st_transform(2163)

# Load ZCTAs locs from CSV, convert to geometry, then join containing state
zcta_centroids <- readr::read_csv("input/2010/zcta/pop_wtd_centroids.csv.bz2") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE) %>%
  st_transform(2163) %>%
  st_join(states_df, join = st_within)

# For ZCTAs missing a spatially joined state, I manually match them to the
# nearest/correct state
zcta_centroids <- zcta_centroids %>%
  mutate(
    state_id = case_when(
      id == "04745" ~ "23",
      id == "55725" ~ "27",
      id == "96769" ~ "15",
      TRUE ~ state_id
    )
  )
  
# For each state, create origins for all ZCTAs inside the state proper
# and destinations for all ZCTA centroids inside the 100 km buffer
for (state in us_states) {
  print(paste("Saving state number:", state))
  
  # Create dir in tract_resources/ to store OD files if not exists
  state_dir_zcta <- glue("input/2010/zcta/origin_destination_by_state/{state}")
  if (!dir.exists(state_dir_zcta)) dir.create(state_dir_zcta)
  
  # Get all origins using FIPS codes
  zcta_centroids %>%
    filter(state_id == state) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(state_dir_zcta, "origins.csv"))
  
  # Load the 100 km buffer from file 
  state_100_km_buffer <- st_read(
    glue("input/shared/buffers/{state}.geojson"),
    quiet = TRUE
  ) %>%
    select(buffer_state = state_id) %>%
    st_transform(2163)
  
  # Get all destinations within the 100 km buffer
  destinations <- zcta_centroids %>%
    st_join(state_100_km_buffer, join = st_within) %>%
    filter(!is.na(buffer_state)) %>%
    select(id, lat, lon) %>%
    st_set_geometry(NULL) %>%
    readr::write_csv(file.path(state_dir_zcta, "destinations.csv"))
}
