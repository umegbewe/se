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
source "transaction_manager.sh"
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

    if [[ -z "$backup_name" ]]; then
        handle_error "Backup name is required" 1
    fi

    create_backup "$backup_name"
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to create backup: $backup_name" 1
    fi

    log_message "Backup created successfully: $backup_name"
}

function restore_data() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        handle_error "Backup name is required" 1
    fi

    restore_backup "$backup_name"
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to restore backup: $backup_name" 1
    fi

    log_message "Data restored successfully from backup: $backup_name"
}

function async_query_data() {
    local query="$1"

    if [[ -z "$query" ]]; then
        handle_error "Query is required" 1
    fi

    local query_id=$(submit_async_query "$query")
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to submit async query: $query" 1
    fi

    echo "Async query submitted successfully: $query_id"
}

function check_async_query() {
    local query_id="$1"

    if [[ -z "$query_id" ]]; then
        handle_error "Query ID is required" 1
    fi

    local status=$(check_async_query_status "$query_id")
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to check async query status: $query_id" 1
    fi

    echo "Async query status: $status"
}


function get_async_query() {
    local query_id="$1"

    if [[ -z "$query_id" ]]; then
        handle_error "Query ID is required" 1
    fi

    local result=$(get_async_query_result "$query_id")
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to get async query result: $query_id" 1
    fi

    echo "Async query result: $result"
    echo "$result"
}


function query_data() {
    local query="$1"
    local collection=${2:-1}
    local limit=${3:-10}

    if [[ -z "$query" ]]; then
        handle_error "Query is required" 1
    fi

    local result=$(perform_query "$query" "$collection" "$limit")
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to query data: $query" 1
    fi

    echo "Query result:"
    echo "$result"

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

load_collections