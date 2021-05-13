##################################################
## Brief: Identify discontinuities in travel times to adjacent tracts.
## Date: 05/13/2021
## Author: Eric Chandler <echandler@uchicago.edu>
## Details: Builds linear model of travel time on distance, bearing, and origin.
##          Large residuals should indicate origin-destination pairs where 
##          routing has failed.
## 
## NOTE: I'm not sure how useful this method is. Instead, try
##        `discontinuity_finder_differential.R` which I think is more intuitive.
##
##################################################

library(readr)
library(dplyr)
library(glue)
library(sf)
library(ggplot2)
library(purrr)
library(geosphere)

# Set target county, geography, and env vars
target_year <- "2010"
target_state <- "24" # {24 : Maryland} , {36 : New York}, {17 : Illinois}
target_geography <- "tract"
target_county <- "031" # {031 : Cook, IL} {081 : Queens, NY} {031 : Montgomery, MD}
target_od_path <- glue(
  "input/{target_year}/{target_geography}/",
  "origin_destination_by_state/{target_state}/"
)
mode <- c("WALK","TRANSIT")
target_mode <- paste(mode, collapse='-')
target_ttm_dir <- glue("output/{target_year}/{target_geography}/travel_time_matrices/{target_state}/{target_mode}")

# Load origins and destinations from resources/ dir
origins <- readr::read_csv(glue(target_od_path, "/origins.csv")) %>% mutate(ID_INT = as.numeric(id))
destinations <- readr::read_csv(glue(target_od_path, "/destinations.csv")) %>% mutate(ID_INT = as.numeric(id))

# Read r5r output
tt_mat <- read.csv(glue(target_ttm_dir, "/ttm.csv")) %>%
  left_join(origins, by = c("fromId" = "ID_INT"), suffix = c(".tt", ".org")) %>%
  left_join(destinations, by = c("toId" = "ID_INT"), suffix = c(".org", ".dest"))

# Compute distances
tt_mat$org <- st_as_sf(tt_mat, coords = c("lon.org", "lat.org"))
tt_mat$dest <- st_as_sf(tt_mat, coords = c("lon.dest", "lat.dest"))
tt_mat$dist <- st_distance(tt_mat$org, tt_mat$dest, by_element=TRUE)
tt_mat$bearing <- sapply(1:nrow(tt_mat), function(i){bearing(c(tt_mat$lon.org[i], tt_mat$lat.org[i]), 
                                                             c(tt_mat$lon.dest[i], tt_mat$lat.dest[i]))})

# Find outliers: i.e. high deviation from linear model of time vs distance
ols_data <- tt_mat %>% select(travel_time, dist, bearing, lon.org, lat.org)
# XXX: wanted to do fixed effects dummy variables lon fromId but ran out of memory
tt_model <- lm(travel_time ~ dist + bearing + lon.org * lat.org, data = ols_data)
tt_model_sigma <- (summary(tt_model))$sigma
ols_data <- ols_data %>% mutate(residuals = tt_model$residuals,
                                abs_residuals = abs(tt_model$residuals),
                                std_residuals = abs_residuals / tt_model_sigma)

# Print most unexpected travel times:
ols_data %>% arrange(desc(std_residuals)) %>% head()

# Plot residuals
ggplot(ols_data) + geom_point(aes(x=dist, y=travel_time, color=std_residuals)) +
  labs(title="Travel Time vs Distance", x="Distance", y="Travel Time", color="OLS Std. Residuals")
