library(tigris)
library(dplyr)
library(sf)
library(glue)
options(tigris_use_cache = TRUE)

# Load list of US state FIPS codes, ignore territories and PR
us_states <- unique(fips_codes$state_code)[1:51]

# Download state boundaries from TIGER/Line
state_buffers_100 <- states(year = 2010) %>%
  filter(GEOID10 %in% us_states) %>%
  st_transform(2163) %>% 
  st_buffer(100000) %>%
  select(state_id = GEOID10) %>%
  st_transform(4326)

# Buffering Alaska will wrap the coords around the prime meridian. This simple
# fix makes sure the buffer for alaska only extend to -179.99
ak_bbox <- st_bbox(c(
    xmin = -179.99, xmax = -111.12,
    ymin = 40.0 , ymax = 74.12)
  ) %>%
  st_as_sfc() %>%
  st_set_crs(4326) %>%
  st_transform(2163) %>%
  st_buffer(-100000) %>%
  st_transform(4326)

ak_poly <- states(year = 2010) %>%
  filter(GEOID10 == "02") %>%
  st_transform(4326) %>%
  st_crop(ak_bbox) %>%
  st_transform(2163) %>%
  st_buffer(100000) %>%
  st_transform(4326)

# Replace the Alaska geometry with fixed buffer
state_buffers_100$geometry[state_buffers_100$state_id == "02"] <- ak_poly$geometry

# For each state, save a geojson of the 100km buffer
for (state in us_states) {
  st_write(
    state_buffers_100 %>% filter(state_id == state),
    glue("input/shared/buffers/{state}.geojson"),
    delete_dsn = TRUE,
    quiet = TRUE
  )
}
