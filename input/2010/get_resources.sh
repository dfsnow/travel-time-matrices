#!/bin/bash

# Set URLs and filenames for OSM
export buffer_size="200"
export osm_url="https://download.geofabrik.de"
export osm_file="north-america-latest.osm.pbf"

# Unpack included tarball files
echo "Unpacking included tarballs..."
tar -xzf county/buffers.tar.gz
tar -xzf tract/resources.tar.gz

# Get OSM North America file if missing
if [ ! -f "$PWD"/shared/"$osm_file" ]; then
    echo "Downloading North American OSM extract from Geofabrik..."
    curl "$osm_url"/"$osm_file" --output "$PWD"/shared/"$osm_file"
fi

# Create a clipped PBF of the buffered county in the shared dir, then symlink
# it to geography-specific dirs
for county in $(cat county/geoid_list.txt); do
    # if [ ! -f "$PWD"/shared/"$county".pbf ]; then
        # echo "Creating a clipped PBF of OSM ways for '$county' county buffer..."
        # clipping_poly="county/buffers/'$county'_'$buffer_size'.geojson"
        # osmium extract -p "$clipping_poly" \
            # "$PWD"/shared/"$osm_file" \
            # --overwrite --progress \
            # -o "$PWD"/shared/"$county".pbf
    # fi
done

