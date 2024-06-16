#!/bin/bash

DATA_DIR="data"
RECORD_FILE_PREFIX="record_"

source "async_query.sh"
source "cache_manager.sh"
source "errors.sh"
source "backup_restore.sh"
source "errors.sh"
source "index_operations.sh"
source "logging.sh"
source "query_parser.sh"
source "query-engine.sh"
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

function async_query_data() {
    local query="$1"

    submit_async_query "$query"
}

function check_async_query() {
    local query_id="$1"

    check_async_query_status "$query_id"
}


function get_async_query() {
    local query_id="$1"

    get_async_query_result "$query_id"
}


function query_data() {
    local query="$1"
    local collection=${2:-1}
    local limit=${3:-10}

    perform_query "$query" "$page" "$limit"
}

# function advanced_query_data() {
#     local collection="$1"
#     local query_condition="$2"

#     perform_advanced_query "$collection" "$query_condition"
# }

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
        --query)
            query="$2"
            shift
            page=${2:-1}
            shift
            limit=${2:-10}
            query_data "$query" "$page" "$limit"
            shift
            ;;
        --async-query)
            query="$2"
            async_query_data "$query"
            shift 2
            ;;
        --check-async-query)
            query_id="$2"
            check_async_query "$query_id"
            shift 2
            ;;
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
done

#load_collections