# 2010 Routing Resources

Routing requires three (plus one optional) data sets within the same directory:

1. A set of origins, saved as a CSV named `origins.csv` with the columns `id`, `lat`, and `lon`
2. A set of destinations, saved as a CSV named `destinations.csv` with the columns `id`, `lat`, and `lon`
3. An extract of the OpenStreetMap street network that covers the routing area, saved as an arbitrarily named `.pbf` file
4. (Optional) Any GTFS feeds that span the routing area, saved as arbitrarily named `.zip` files. Only necessary for transit/multi-modal routing with `r5r`

This directory contains pre-calculated origins (1) and destinations (2) for routing between 2010 Census geographies. Two geographies are included, census tracts and [ZCTAs](https://www.census.gov/programs-surveys/geography/guidance/geo-areas/zctas.html). Origins and destinations **are population-weighted centroids of their respective geographies** (based on 2010 census block populations).

OSM data (3) and GTFS feeds (4) are not included in this directory and must be downloaded separately, see below.

## Usage

Running the scripts in this directory will download all the data necessary for any mode of routing.

1. Clone this repository or download it from GitHub
2. Navigate to `inputs/2010/` (this directory)
3. Unpack the included tarballs by running `extract_tarballs.sh`
3. Download/clip OSM data and save it to the appropriate directories by running `get_osm_data.sh`
4. (Optional) Download GTFS feeds for each routing area by running `get_transit_feeds.R`

:warning: **NOTE** :warning: 

These scripts are essentially downloading the entire street and transit network of the United States. They transfer a significant amount of data, take a long time to run, and use a large amount of disk space (upwards of 50 GB). 

## Directory Structure

This repository treats census counties as discrete routing areas/units of work. For example, when routing between census tracts, origins will be contained within a single county, while destinations will be contained within the 200 km buffer of that county.

As such, routing files are parititioned by county into directories named after each county's FIPS code. These files are stored in the `resources/` folder of each geography (to facilitate routing for different geography's origin-destination sets). OSM files and GTFS feeds are saved in the `shared/` directory, then symlinked to each geography's `resources/` directory to save space.

When all the scripts outlined above have run successfully, the resulting directory structure should look like:

```
tracts/resources/
├── 17031/
│   ├── origins.csv (all origins in county 17031)
│   ├── destinations.csv (all destinations within 200 km buffer of 17031)
│   ├── cta_gtfs.zip (GTFS feed within 200 km buffer, symlinked from shared/)
│   ├── metra.zip
│   └── 17031.pbf (OSM network of 200 km buffer, symlinked from shared/)
├── 17037/
│   ├── origins.csv 
│   ├── destinations.csv
│   ├── metra.zip
│   └── 17037.pbf
├── 17039/
...
```

