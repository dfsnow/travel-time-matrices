## Scripts

The scripts in this directory were used to generate the resources included in this repository (for tracts and ZCTAs). They do not need to be run and are only included for the sake of reproducibility.

### `01_generate_pop_weighted_centroids.R`

Script to convert `../block/lat_lon_pop.csv.bz2` into population-weighted centroids for different geographies. Weighted centroids are calculated using the following steps:

1. Convert block lon/lat into meters ([Albers Equal Area](https://epsg.io/2163))
2. Determine which blocks are inside the target geography (using FIPS codes for tracts, spatial intersection for other geographies)
3. For each geography, calculate the mean block longitude and mean block latitude, weighting by block population
4. Convert the resulting population-weighted centroids back to lon/lat
5. Check that the each population-weighted centroid is inside the polygon boundary of its parent geography, if it is not, set the `unroutable` field to `TRUE` in the output CSV the target geography

### `02_create_origin_destination_files.R`

Script to generate origin and destination CSV files with `id,lat,lon` needed for routing. Files are partitioned by state and saved to their respective geography's directory. `origins.csv` contains all geographic units whose population-weighted centroids lie within the state itself. `destinations.csv` contains all geographic units whose population-weighted centroids lie within the state's 100 km buffer.
