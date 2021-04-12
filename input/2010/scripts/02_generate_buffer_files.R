library(tigris)
library(dplyr)
library(sf)
library(glue)
options(tigris_use_cache = TRUE)

# Load continental US counties from file
county_ids <- read_table(
  "input/2010/county/geoid_list.txt",
  col_names = c("county")
) %>%
  pull(county)

# 100 km buffer used to find destination around the target county
county_buffers_100 <- counties(year = 2010) %>%
  filter(GEOID10 %in% county_ids) %>%
  st_transform(2163) %>%
  st_buffer(100000) %>%
  select(county_id = GEOID10) %>%
  st_transform(4326)

# 200 km buffer used to clip the OSM road network around the 100 km buffer
county_buffers_200 <- counties(year = 2010) %>%
  filter(GEOID10 %in% county_ids) %>%
  st_transform(2163) %>%
  st_buffer(200000) %>%
  select(county_id = GEOID10) %>%
  st_transform(4326)

# For each county, save both 100km and 200km buffers
for (county in county_ids) {
  print(paste("Saving county number:", county))
  st_write(
    county_buffers_100 %>% filter(county_id == county),
    glue("input/2010/county/buffers/{county}_100.geojson"),
    delete_dsn = TRUE,
    quiet = TRUE
  )
  st_write(
    county_buffers_200 %>% filter(county_id == county),
    glue("input/2010/county/buffers/{county}_200.geojson"),
    delete_dsn = TRUE,
    quiet = TRUE
  )
}
