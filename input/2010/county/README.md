## Files

#### `county/buffers.tar.gz`

Tarball of buffered 2010 county boundaries saved as GeoJSONs. Two buffer sizes are included:

* Files ending with `_100` are counties with a 100 km buffer and are used to find destinations locations
* Files ending with `_200` are counties with a 200 km buffer and are used to clip the OpenStreetMap network 

The street clipping buffer should be larger than the destination-finding buffer to ensure that destinations don't end up on street network islands created by the buffer clipping.

#### `county/geoid_list.txt`

Headerless text list of all 2010 county GEOIDs in the United States. Does not include territories, PR, etc. Sourced from TIGER/Line files (via the [tigris R package](https://cran.r-project.org/web/packages/tigris/index.html)).

