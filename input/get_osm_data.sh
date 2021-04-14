#!/bin/bash

# Set URLs and filenames for OSM
export buffer_size="200"
export osm_url="https://download.geofabrik.de"
export osm_file="north-america-latest.osm.pbf"

# Get OSM North America file if missing
if [ ! -f "$PWD"/shared/"$osm_file" ]; then
    echo "Downloading North American OSM extract from Geofabrik..."
    curl "$osm_url"/"$osm_file" --output "$PWD"/shared/"$osm_file"
fi

# Create a clipped PBF of the buffered county in the shared dir, then symlink
# it to geography-specific dirs
for county in $(cat county/temp.txt); do
    mkdir -p "$PWD"/shared/osm
    if [ ! -f "$PWD"/shared/osm/"$county".pbf ]; then
        echo "Creating a clipped PBF of OSM ways for $county county buffer..."
        clipping_poly="${PWD}/county/buffers/${county}_${buffer_size}.geojson"
        osmium extract -p "$clipping_poly" \
            "$PWD"/shared/"$osm_file" \
            --overwrite --progress \
            -o "$PWD"/shared/osm/"$county".pbf
    fi
    echo "Done! Symlinking PBF to tracts/ and zcta/ directories..."
    if [ ! -L "$PWD"/tract/resources/"$county"/"$county".pbf ]; then
        ln -s "$PWD"/shared/osm/"$county".pbf "$PWD"/tract/resources/"$county"/"$county".pbf
    fi
    if [ ! -L "$PWD"/zcta/resources/"$county"/"$county".pbf ]; then
        ln -s "$PWD"/shared/osm/"$county".pbf "$PWD"/zcta/resources/"$county"/"$county".pbf
    fi
done

