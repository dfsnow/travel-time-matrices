library(tigris)
library(dplyr)
library(sf)
library(jsonlite)
library(purrr)
library(glue)

# Load continental US counties from file
county_ids <- readr::read_table(
  "input/2010/county/geoid_list.txt",
  col_names = c("county")
) %>%
  pull(county)

# Load Transit Feeds API key from .Renviron file at root of project directory
# To get an API key, visit https://transitfeeds.com/api/
api_key <- Sys.getenv("TRANSIT_FEEDS_API_KEY")

# Instead of loading buffered counties 1 by 1, just load all counties then
# apply the same 200 km buffer
counties_df <- counties(year = 2010) %>%
  select(county_id = GEOID10) %>%
  filter(county_id %in% county_ids) %>%
  st_transform(2163) %>%
  st_buffer(200000)

# Get a list of all feeds locations worldwide (which contain individual feeds)
feed_locations_url <- paste0(
  "https://api.transitfeeds.com/v1/getLocations?key=", api_key
)
feed_locations_df <- bind_rows(
  jsonlite::read_json(feed_locations_url)$results$locations
) %>%
  st_as_sf(coords = c("lng", "lat"), crs = 4326) %>%
  st_transform(2163) %>%
  select(id)

# Figure out which feed locations are in which county buffers
feed_locations_df <- counties_df %>%
  st_join(feed_locations_df, join = st_contains) %>%
  filter(!is.na(id)) %>%
  st_set_geometry(NULL)

# For each county get a list of associated locs and feed IDs
feeds_df <- feed_locations_df %>%
  distinct(loc_id = id) %>%
  mutate(
    query_url = paste0(
      "https://api.transitfeeds.com/v1/getFeeds?key=", api_key,
      "&location=", loc_id,
      "&descendants=1&page=1&limit=100&type=gtfs"
    )
  ) %>%
  mutate(feeds = map(
    query_url,
    ~ map(
      read_json(.x)$results$feeds, 
      ~ .x[["id"]])
    )
  ) %>%
  right_join(feed_locations_df, by = c("loc_id" = "id")) %>%
  group_by(county_id) %>%
  summarize(
    loc_ids = list(loc_id),
    feed_ids = list(unlist(feeds))
  )

# Save feeds list to JSON
feeds_json <- feeds_df %>%
  jsonlite::toJSON()
write(feeds_json, "input/2010/shared/feeds_by_county.json")
rm(feeds_json)
  
# Download all feeds associated with counties
for (feed_id in unique(unlist(feeds_df$feed_ids))) {
  feed_path <- file.path(
    "input/2010/shared/feeds/",
    paste0(stringr::str_replace_all(feed_id, "/", "-"), ".zip")
  )
  if (!file.exists(feed_path)) {
    download.file(
      paste0(
        "https://api.transitfeeds.com/v1/getLatestFeedVersion?key=",
        api_key, "&feed=", feed_id
      ),
      feed_path
    )
  }
}

# Each feed is downloaded once to shared/ then symlinked to the relevant county
# level folders
for (county in unique(feeds_df$county_id)) {
  print(paste0("Linking county: ", county))
  feeds <- feeds_df %>%
    filter(county == county_id) %>%
    pull(feed_ids)
  feeds <- paste0(stringr::str_replace_all(feeds[[1]], "/", "-"), ".zip")
  
  # Link each feed for each county to both tracts and ZCTA geographies
  for (feed in feeds) {
    R.utils::createLink(
      link = glue("input/2010/tract/resources/{county}/", feed),
      target = glue("input/2010/shared/feeds/", feed),
      overwrite = TRUE
    )
    R.utils::createLink(
      link = glue("input/2010/zcta/resources/{county}/", feed),
      target = glue("input/2010/shared/feeds/", feed),
      overwrite = TRUE
    )
  }
}

