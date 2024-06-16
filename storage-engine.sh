#!/bin/bash

DATA_DIR="data"
RECORD_FILE_PREFIX="record_"

source "backup_restore.sh"
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

function backup_data() {
    local backup_name="$1"

    create_backup "$backup_name"
}

function restore_data() {
    local backup_name="$1"
    restore_backup "$backup_name"
}

while [[ $# -gt 0 ]]; do 
    case "$1" in
        --backup)
            backup_name="$2"
            backup_data "$backup_name"
            shift 2
            ;;
        --restore)
            backup_name="$2"
            restore_data "$backup_name"
            shift 2
            ;;
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
done

#load_collections