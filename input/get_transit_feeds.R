library(tigris)
library(dplyr)
library(sf)
library(jsonlite)
library(purrr)
library(glue)

# Load list of US state FIPS codes, ignore territories and PR
us_states <- unique(tigris::fips_codes$state_code)[1:51]

# Load Transit Feeds API key from .Renviron file at root of project directory
# To get an API key, visit https://transitfeeds.com/api/
api_key <- Sys.getenv("TRANSIT_FEEDS_API_KEY")

# Load state buffers from files
states_df <- map_dfr(
  us_states, ~ st_read(glue("input/shared/buffers/", .x, ".geojson"))
  ) %>%
  st_transform(2163)

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

# Figure out which feed locations are in which state buffers
feed_locations_df <- states_df %>%
  st_join(feed_locations_df, join = st_contains) %>%
  filter(!is.na(id)) %>%
  st_set_geometry(NULL)

# For each state get a list of associated locs and feed IDs
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
  group_by(state_id) %>%
  summarize(
    loc_ids = list(loc_id),
    feed_ids = list(unlist(feeds))
  )

# Download all feeds contained within all states
for (feed_id in unique(unlist(feeds_df$feed_ids))) {
  feed_path <- file.path(
    "input/shared/feeds",
    paste0(stringr::str_replace_all(feed_id, "/", "-"), ".zip")
  )
  if (!file.exists(feed_path)) {
    curl::curl_download(
      paste0(
        "https://api.transitfeeds.com/v1/getLatestFeedVersion?key=",
        api_key, "&feed=", feed_id
      ),
      feed_path
    )
  }
}

# Each feed is downloaded once to shared/feeds/ then symlinked to
# the relevant state level graphs/ folder
for (state in unique(feeds_df$state_id)) {
  print(paste0("Linking state: ", state))
  feeds <- feeds_df %>%
    filter(state_id == state) %>%
    pull(feed_ids)
  feeds <- paste0(stringr::str_replace_all(feeds[[1]], "/", "-"), ".zip")
  
  # Link each feed to the relevant state folder
  for (feed in feeds) {
    R.utils::createLink(
      link = glue("input/shared/graphs/{state}/", feed),
      target = glue("input/shared/feeds/", feed),
      overwrite = TRUE
    )
  }
}

