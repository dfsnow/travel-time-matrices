library(tigris)
library(tidycensus)
library(dplyr)
library(sf)
library(purrr)
options(tigris_use_cache = TRUE)
states <- unique(fips_codes$state_code)[1:51]

# Load census block centroids from file
blocks <- readr::read_csv(
  file = "input/2010/block/lat_lon_pop.csv.bz2",
  col_types = c("id" = "c", "pop" = "i", "lon" = "n", "lat" = "n")
)

# Convert centroids to equal area projection to facilitate taking their mean
blocks <- blocks %>%
  mutate(tract_id = stringr::str_sub(id, 1, 11)) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(2163) %>%
  mutate(
    x = st_coordinates(.)[,1],
    y = st_coordinates(.)[,2]
  )



##### Tracts #####

# For each tract, get the average of block centroids (in meters, weighted by
# population from the 2010 census)
# + 1 offset for weighted mean because some tracts have only blocks with
# zero population
tract_centroids <- blocks %>%
  st_set_geometry(NULL) %>%
  group_by(tract_id) %>%
  summarize(
    pop_wtd_x = weighted.mean(x, pop + 1),
    pop_wtd_y = weighted.mean(y, pop + 1),
    pop_total = sum(pop)
  ) %>%
  st_as_sf(coords = c("pop_wtd_x", "pop_wtd_y"), crs = 2163) %>%
  st_transform(4326) %>%
  mutate(
    pop_wtd_lon = st_coordinates(.)[,1],
    pop_wtd_lat = st_coordinates(.)[,2]
  ) %>%
  st_set_geometry(NULL) %>%
  ungroup()

# Download tract geometries in order to gut check pop. weighted centroids
tract_geometries <- reduce(
  map(states, function(x) get_acs(
      geography = "tract", variables = "B01003_001", 
      state = x, geometry = TRUE, year = 2010
  )), 
  rbind
) %>%
  st_transform(4326) %>%
  left_join(tract_centroids, by = c("GEOID" = "tract_id"))

# Check if pop. weighted tract centroid is inside tract polygon
tract_geometries_check <- tract_geometries %>%
  mutate(
    tract_contains_centroid = as.numeric(st_contains(
      .,
      st_as_sf(., coords = c("pop_wtd_lon", "pop_wtd_lat"), crs = 4326))
    ),
    tract_contains_centroid = !is.na(tract_contains_centroid == row_number())
  ) %>%
  mutate(unroutable = !tract_contains_centroid & (estimate == 0)) %>%
  select(
    id = GEOID,
    acs_pop = estimate, acs_moe = moe,
    block_pop = pop_total,
    lon = pop_wtd_lon, lat = pop_wtd_lat,
    unroutable
  ) %>%
  st_set_geometry(NULL)

# Save tracts to file
tract_geometries_check %>%
  readr::write_csv("input/2010/tract/pop_wtd_centroids.csv", na = "")



##### ZCTAs #####

# Download all ZCTA geometries from the 2010 census
zcta_geometries <- zctas(cb = TRUE, year = 2010) %>%
  select(zcta_id = ZCTA5) %>%
  st_transform(2163)

# Find all census blocks within each ZCTA, then summarize to get pop-weighted
# centroids
# Also remove 00 zips (these are for PR)
zcta_joined <- zcta_geometries %>%
  st_join(blocks, join = st_contains) %>%
  st_set_geometry(NULL)

zcta_centroids <- zcta_joined %>%
  group_by(zcta_id) %>%
  summarize(
    pop_wtd_x = weighted.mean(x, pop + 1),
    pop_wtd_y = weighted.mean(y, pop + 1),
    pop_total = sum(pop)
  ) %>%
  st_as_sf(coords = c("pop_wtd_x", "pop_wtd_y"), crs = 2163) %>%
  st_transform(4326) %>%
  mutate(
    pop_wtd_lon = st_coordinates(.)[,1],
    pop_wtd_lat = st_coordinates(.)[,2]
  ) %>%
  st_set_geometry(NULL) %>%
  ungroup()

# Check if pop. weighted ZCTA centroid is inside ZCTA polygon
zcta_geometries_check <- zcta_geometries %>%
  left_join(zcta_centroids, by = c("zcta_id")) %>%
  mutate(
    zcta_contains_centroid = as.numeric(st_contains(
      .,
      st_as_sf(., coords = c("pop_wtd_lon", "pop_wtd_lat"), crs = 4326))
    ),
    zcta_contains_centroid = !is.na(zcta_contains_centroid == row_number())
  ) %>%
  mutate(unroutable = !zcta_contains_centroid) %>%
  select(
    id = zcta_id,
    block_pop = pop_total,
    lon = pop_wtd_lon, lat = pop_wtd_lat,
    unroutable
  ) %>%
  st_set_geometry(NULL)

# Remove Puerto Rico ZCTAs then save to disk
zcta_geometries_check %>%
  filter(stringr::str_starts(id, "00", negate = TRUE)) %>%
  readr::write_csv("input/2010/zcta/pop_wtd_centroids.csv", na = "")
