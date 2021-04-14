library(r5r)
library(sf)
library(dplyr)
library(glue)
options(java.parameters = "-Xmx6G")

# Set target county, geography, and env vars
target_year <- "2010"
target_county <- "17031"
target_geography <- "tract"
target_path <- glue(
  "input/{target_year}/{target_geography}/resources/{target_county}"
)

# Load origins and destinations from resources/ dir
origins <- readr::read_csv(glue(target_path, "/origins.csv"))  
destinations <- readr::read_csv(glue(target_path, "/destinations.csv")) 

# Setup routing path and r5 instance
r5r_core <- setup_r5(data_path = target_path, verbose = TRUE, temp_dir = TRUE)

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
