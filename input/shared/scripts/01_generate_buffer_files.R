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

# For each state, save a geojson of the 100km buffer
for (state in us_states) {
  print(paste("Saving state number:", state))
  st_write(
    state_buffers_100 %>% filter(state_id == state),
    glue("input/shared/buffers/{state}.geojson"),
    delete_dsn = TRUE,
    quiet = TRUE
  )
}
