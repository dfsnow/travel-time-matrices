# Routing Inputs

Routing requires three (plus one optional) data sets:

1. A set of origins, saved as a CSV with the columns `id`, `lat`, and `lon`
2. A set of destinations, saved as a CSV with the columns `id`, `lat`, and `lon`
3. An extract of the OpenStreetMap street network that covers the routing area, saved as an arbitrarily named `.pbf` file
4. (Optional) Any GTFS feeds that span the routing area, saved as arbitrarily named `.zip` files. Only necessary for transit/multi-modal routing with `r5r`

This directory contains pre-calculated origins (1) and destinations (2) for common Census geographies and years, see each Census year for more details. This directory does ***NOT*** contain the OSM data (3) or GTFS feeds (4) necessary to perform routing. However, scripts to fetch these resources are included, see [Usage](#usage).

## Usage

Running the scripts in this directory will download all the data necessary for any mode of routing.

0. Install [Git LFS](https://docs.github.com/en/github/managing-large-files/installing-git-large-file-storage)
    (To pull individual files, use:
    `> git lfs checkout path/to/file`)
1. Clone this repository or download it from GitHub
2. Install [Osmium](https://osmcode.org/osmium-tool/manual.html)
3. Run `get_osm_data.sh` to download/clip OSM data and save it to the appropriate directory
4. (Optional) Run `get_transit_feeds.R` to download GTFS feeds for each routing area
5. If a network.dat file exists alongside the OSM or GTFS data, r5r will use the .dat file and ignore the new feeds/maps. Deleting the network.dat file will force r5r to incorporate new GTFS or OSM data.

:warning: **NOTE** :warning: 

These scripts are essentially downloading the entire street and transit network of the United States. They transfer a significant amount of data, take a long time to run, and use a large amount of disk space.
