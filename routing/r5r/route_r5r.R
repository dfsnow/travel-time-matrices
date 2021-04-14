library(r5r)
library(sf)
library(dplyr)
library(glue)
options(java.parameters = "-Xmx6G")

# Set target county, geography, and env vars
target_year <- "2010"
target_state <- "01"
target_geography <- "tract"
target_graph_path <- glue("input/shared/graphs/{target_state}/")
target_od_path <- glue(
  "input/{target_year}/{target_geography}/",
  "origin_destination_by_state/{target_state}/"
)

# Load origins and destinations from resources/ dir
origins <- readr::read_csv(glue(target_od_path, "/origins.csv"))  
destinations <- readr::read_csv(glue(target_od_path, "/destinations.csv")) 

# Setup routing path and r5 instance
r5r_core <- setup_r5(
  data_path = target_graph_path,
  verbose = TRUE,
  temp_dir = TRUE
)

# Create travel times matrix for transit routing
start_time <- Sys.time()
mat <- travel_time_matrix(
  r5r_core = r5r_core,
  origins = origins,
  destinations = destinations,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = Sys.time(),
  time_window = 10,
  max_walk_dist = Inf,
  max_trip_duration = 2000,
  max_rides = 5,
  verbose = FALSE
)
end_time <- Sys.time()
runtime <- end_time - start_time
