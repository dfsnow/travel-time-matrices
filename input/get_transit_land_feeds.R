##################################################
## Brief: Downloads GTFS feeds from Transit Land API v1
## Date: 05/13/2021
## Author: Eric Chandler <echandler@uchicago.edu>
##################################################

library(tigris)
library(dplyr)
library(sf)
library(jsonlite)
library(purrr)
library(glue)

# Step 1: Get Basic Geographic Bounds  ---------------------------------------

# Load list of US state FIPS codes, ignore territories and PR
us_states <- unique(tigris::fips_codes$state_code)[1:51]

# Load Transit-Land API key from .Renviron file at root of project directory
# To get an API key, visit https://www.transit.land/documentation#signing-up-for-an-api-token
# API key not needed for TransitLand v1 
# api_key <- Sys.getenv("TRANSIT_LAND_API_KEY")

# Load state buffers from files
states_df <- map_dfr(
  us_states, ~ st_read(glue("input/shared/buffers/", .x, ".geojson"))
) %>% st_transform(2163)

states_outline <- states_df %>% st_union()
states_bbox <- states_outline %>% st_bbox() 

# Step 2: Get List Feeds + Metadata ---------------------------------------

# Create API URL bounded to roughly the usa
feed_locations_url <- paste0(
  "https://transit.land/api/v1/feeds?per_page=50"
)

# @NICO How to re-project these coordinates to long/lat?
bbox_querystring <- paste0("bbox=",
                           states_bbox$xmin, ",", states_bbox$ymin, ",", 
                           states_bbox$xmax, ",", states_bbox$ymax)

# Create list to hold feeds
feed_onestop_ids <- c()

# Feeds results are paginated so we need to make multiple API requests
while (feed_locations_url) {
  feed_locations_json <- jsonlite::read_json(feed_locations_url)
  # TODO: Refactor for-loop to be more R-like
  for (feed in feed_locations_json$feeds) {
    # Double-check records are complete (sometimes they're missing coordinates)
    if (feed$feed_format == "gtfs" && 
        "geometry" %in% names(feed) &&
        "coordinates" %in% names(feed$geometry) &&
        length(feed$geometry$coordinates) > 0) {
      
      coords <- unlist(feed$geometry$coordinates)
      lonlats <- split(coords, 1:2)
      coords_df <- data.frame(lon = lonlats$`1`, lat = lonlats$`2`)
      
      coords_df <- st_as_sf(coords_df, coords = c("lon", "lat"), crs = 4326) %>% st_transform(2163)
      # @NICO ^^ is this a reasonable projection?
      
      # XXX: The feeds metadata  contains USA locations, but this isn't correctly filtering
      # If any coordinates from this feed intersect the us, keep it.
      if (any(st_intersects(coords_df, states_outline, sparse=FALSE))) {
        feed_onestop_ids <- append(feed_onestop_ids, feed$onesteop_id)
      }
    }
  }
  # XXX: Hopefully 'next' evaluates to some falsy value when we reach last result...
  feed_locations_url <- feed_locations_json$meta[['next']]
}

# Step 3: Get GTFS  ---------------------------------------

# TODO ... for each onestop_id, GET /api/v1/feeds/<onestop_id>
