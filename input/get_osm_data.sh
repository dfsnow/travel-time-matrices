#!/bin/bash

# Set URLs and filenames for OSM
export osm_url="https://download.geofabrik.de"
export osm_file="north-america-latest.osm.pbf"

# Get OSM North America file if missing
if [ ! -f "$PWD"/shared/"$osm_file" ]; then
    echo "Downloading North American OSM extract from Geofabrik..."
    curl "$osm_url"/"$osm_file" --output "$PWD"/shared/"$osm_file"
fi

# Create a clipped PBF for each buffered state
for state in $(cat shared/state_fips.txt); do
    if [ ! -f "$PWD"/shared/graphs/"$state"/"$state".pbf ]; then
        echo "Creating a clipped PBF of OSM ways for ${state} state buffer..."
        clipping_poly="${PWD}/shared/buffers/${state}.geojson"
        osmium extract -p "$clipping_poly" \
            "$PWD"/shared/"$osm_file" \
            --overwrite --progress \
            -o "$PWD"/shared/graphs/"$state"/"$state".pbf
    fi
done

