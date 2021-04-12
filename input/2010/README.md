# 2010 Resources

Routing inputs in this directory are based on the 2010 decennial Census. 

### `01_generate_pop_weighted_centroids.R`

Script to convert `block_locs_and_pops.csv.bz2` into population-weighted centroids for different geographies. Weighted centroids are calculated using the following steps:

1. Convert block lon/lat into meters ([Albers Equal Area](https://epsg.io/2163))
2. Determine which blocks are inside the target geography (using FIPS codes for tracts, spatial intersection for other geographies)
3. For each geography, calculate the mean block longitude and mean block latitude, weighting by block population
4. Convert the resulting population-weighted centroids back to lon/lat
5. Check that the each population-weighted centroid is inside the polygon boundary of its parent geography, if it is not, set the `unroutable` field to `TRUE` in the output CSV the target geography
6. Save output CSV to top-level directory of the target geography (`tracts/` for Census tracts)

### `block_locs_and_pops.csv.bz2`

Census block lon, lat, and population count. Sourced from the [Census FTP site](ftp://ftp.census.gov/geo/tiger/) and combined with CLI utilities.

- Locations come from the interior point fields (`INTPLON10` and `INTPLAT10`) of the [2010 TABBLOCK files](https://www2.census.gov/geo/tiger/TIGER2010/TABBLOCK/2010/)
- Populations come from the `POP10` field of the [2010 BLKPOPHU files](https://www2.census.gov/geo/tiger/TIGER2010BLKPOPHU/)

### `county_geoids_list.txt`

Headerless text list of all 2010 county GEOIDs. Sourced from [here](https://www2.census.gov/geo/tiger/TIGER2010/COUNTY/2010/).


