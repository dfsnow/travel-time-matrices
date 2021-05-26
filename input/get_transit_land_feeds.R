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

# Load Transit-Land API key from .Renviron file at root of project directory
# To get an API key, visit https://www.transit.land/documentation#signing-up-for-an-api-token
# API key not needed for TransitLand v1
# api_key <- Sys.getenv("TRANSIT_LAND_API_KEY")

# Load lower 48 states' geographies
us_states <- tigris::states(cb=TRUE) %>%
  filter(!(STUSPS %in% c('HI','AK','AS','GU','MP','PR','VI'))) %>%
  st_transform(crs = st_crs(4326)) %>% st_as_sf()

# Create bounding box per state
us_states <- cbind(us_states, sapply(us_states$geometry, st_bbox) %>% t())

# Step 2: Get List Feeds + Metadata ---------------------------------------


#' Gets gtfs feeds inside a state's bounding box from TransitLand
query_onestop_ids <- function(xmin, ymin, xmax, ymax) {
  feed_locations_url <- "https://transit.land/api/v1/feeds?per_page=5"
  bbox_querystring <- paste0("bbox=",
                             xmin, ",", ymin, ",",
                             xmax, ",", ymax)
  query_url <- paste0(feed_locations_url, "&", bbox_querystring)
  feed_onestop_ids <- c()
  # Feeds results are paginated so we need to make multiple API requests
  while (!is.null(query_url)) {
    # Wait a few seconds to avoid rate limits?
    Sys.sleep(runif(1)*2)
    print(paste("Querying API: ", query_url))
    # Server may refuse connection
    feed_locations_json <- tryCatch(jsonlite::read_json(query_url),
                                    error=function(e){print(e);NULL})
    if (is.null(feed_locations_json)){
      return(feed_onestop_ids);
    }
    for (feed in feed_locations_json$feeds){
      inner_feed <- feed %>% flatten()
      if (inner_feed$feed_format == "gtfs") {
        feed_onestop_ids <- append(feed_onestop_ids, inner_feed$onestop_id)
      }
    }
    query_url <- feed_locations_json$meta[['next']]
  }
  feed_onestop_ids
}


# Create list to hold feeds
onestop_ids <- c()
# TODO: Refactor to tidy-style now that the function is safe
for (idx in 1:nrow(us_states)) {
  xmin <- us_states$xmin[idx]
  ymin <- us_states$ymin[idx]
  xmax <- us_states$xmax[idx]
  ymax <- us_states$ymax[idx]
  onestop_ids <- append(onestop_ids, query_onestop_ids(xmin,ymin,xmax,ymax))
}
# state_feeds <- us_states %>% mutate(feeds = query_onestop_ids(xmin,ymin,xmax,ymax))

# Step 3: Get GTFS  ---------------------------------------

# TODO ... for each onestop_id, GET /api/v1/feeds/<onestop_id>
