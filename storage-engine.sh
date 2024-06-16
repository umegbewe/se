#!/bin/bash

DATA_DIR="data"
RECORD_FILE_PREFIX="record_"

source "errors.sh"
source "index_operations.sh"
source "record_operations.sh"
source "type-system/type_definitions.sh"
source "type-system/type_validation.sh"
source "type-system/type_utils.sh"

mkdir -p "$DATA_DIR"


function load_collections {
    local collections=$(find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d)

    for collection in $collections; do
        collection_name=$(basename "$collection")
        echo "Loading collection: $collection_name"
    
        local records=$(find "$collection" -type f -name "${RECORD_FILE_PREFIX}*")

        for record_file in $records; do 
            record_id=$(basename "$record_file" | sed "s/${RECORD_FILE_PREFIX}//")
            create_index "$collection_name" "$record_id" "$record_file"
        done
    done
}

load_collections