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

# Set trip parameters
mode <- c("WALK","TRANSIT")
target_mode <- paste(mode, collapse='-')
departure_time <- as.POSIXct(strptime("2021-04-16 20:21:17 CDT","%Y-%m-%d %H:%M:%S"))
departure_time <- Sys.time()

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
  mode = mode,
  departure_datetime = departure_time,
  time_window = 1, 
  max_walk_dist = Inf,
  max_trip_duration = 20000, # duration units = minutes
  max_rides = 5,
  verbose = FALSE
)
end_time <- Sys.time()
runtime <- end_time - start_time
print("Routing matrix finished in :")
print(runtime)

# Write travel time matrix to csv for later analysis
out_dir <- glue("output/{target_year}/{target_geography}/travel_time_matrices/{target_state}/{target_mode}")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive=TRUE)
write.csv(mat, glue(out_dir, "/ttm.csv"))

stop_r5(r5r_core)
