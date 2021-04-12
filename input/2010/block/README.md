## Files

### `lat_lon_pop.csv.bz2`

Census block lat, lon, and population count. Sourced from the [Census FTP site](ftp://ftp.census.gov/geo/tiger/) and combined with CLI utilities. Used to calculate population-weighted centroids for different geographies.

- Locations come from the interior point fields (`INTPLON10` and `INTPLAT10`) of the [2010 TABBLOCK files](https://www2.census.gov/geo/tiger/TIGER2010/TABBLOCK/2010/)
- Populations come from the `POP10` field of the [2010 BLKPOPHU files](https://www2.census.gov/geo/tiger/TIGER2010BLKPOPHU/)

