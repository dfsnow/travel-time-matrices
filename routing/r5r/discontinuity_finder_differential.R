##################################################
## Brief: Identify discontinuities in travel times to adjacent tracts.
## Date: 05/13/2021
## Author: Eric Chandler <echandler@uchicago.edu>
## Details: Measures variance of travel times to adjacent tracts.
##          Tracts with large variance may indicate routing has failed.
##################################################

library(r5r)
library(sf)
library(dplyr)
library(glue)

# Set target county, geography, and env vars
target_year <- "2010"
target_state <- "24"
target_geography <- "tract"
target_od_path <- glue(
  "input/{target_year}/{target_geography}/",
  "origin_destination_by_state/{target_state}/"
)
mode <- c("WALK","TRANSIT")
target_mode <- paste(mode, collapse='-')
target_ttm_dir <- glue("output/{target_year}/{target_geography}/travel_time_matrices/{target_state}/{target_mode}")


# Load origins and destinations from resources/ directory
origins <- readr::read_csv(glue(target_od_path, "/origins.csv")) %>% mutate(ID_INT = as.numeric(id))
destinations <- readr::read_csv(glue(target_od_path, "/destinations.csv")) %>% mutate(ID_INT = as.numeric(id))

# Read r5r output
tt_mat <- read.csv(glue(target_ttm_dir, "/ttm.csv")) %>%
  left_join(origins, by = c("fromId" = "ID_INT"), suffix = c(".tt", ".org")) %>%
  left_join(destinations, by = c("toId" = "ID_INT"), suffix = c(".org", ".dest"))

# Get tracts
tract_geos <- tigris::tracts(as.numeric(target_state)) %>% 
  mutate(GEOID_INT = as.numeric(GEOID)) %>% st_transform(2163)

# Compute adjacent tracts
adjacent_tracts <- tract_geos %>% st_join(tract_geos, join = st_touches) %>% 
  select(GEOID_INT.x, GEOID_INT.y, geometry)
              
# !!REPEAT!! run code from here onwards a few times to spot-check many points!
# Sample one origin tract to reduce memory costs
tt_from_one_origin <- tt_mat %>% select(fromId, toId, travel_time) %>% 
  filter(fromId == sample(tt_mat$fromId,size=1))

# Compute difference in travel time from origin to adjacent tracts
adjacent_times <- adjacent_tracts %>% 
  inner_join(tt_from_one_origin, by = c("GEOID_INT.x" = "toId")) %>%
  inner_join(tt_from_one_origin, by = c("GEOID_INT.y" = "toId")) %>%
  mutate(DIFF = travel_time.x - travel_time.y)

# Compute variance in adjacent tract travel times
var_times <- adjacent_times %>% group_by(fromId.x, GEOID_INT.x, travel_time.x) %>% 
              summarise(VAR_ADJ = sd(travel_time.y),
                        AVG_ADJ = mean(travel_time.y),
                        VAR_DIFF = sd(DIFF), 
                        AVG_DIFF = mean(DIFF), .groups='keep') %>%
              mutate(STD_DIFF = VAR_DIFF/travel_time.x,
                     STD_ADJ = VAR_ADJ/travel_time.x,)

# Plot distribution of travel time variance
ggplot(data = var_times) + geom_boxplot(aes(y=STD_ADJ)) +
  labs(title="Relative variance of travel time to adjacent tracts",
       x="1 Observation = 1 Tract (GEOID)", y="StDev(TTime to Adjacent Tracts)/Mean(TTime to Tract)")

# Spatial plots
ggplot(data = var_times) + geom_sf(aes(fill=travel_time.x)) + 
  labs(title="Baseline travel time", fill="Minutes")

ggplot(data = var_times) + geom_sf(aes(fill=VAR_ADJ)) + 
  labs(title="Variance of travel time vs adjacent tracts", fill="Minutes")

ggplot(data = var_times) + geom_sf(aes(fill=STD_ADJ)) + 
  labs(title="Mean-adjusted variance of travel time vs adjacent tracts", fill="Minutes")
