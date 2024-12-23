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
    local collections
    collections=$(find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d)

    for collection in $collections; do
        local collection_name
        collection_name=$(basename "$collection")
        log_message "Loading collection: $collection_name"
    
        local records
        records=$(find "$collection" -type f -name "${RECORD_FILE_PREFIX}*")

        for record_file in $records; do 
            local record_id
            record_id=$(basename "$record_file" | sed "s/${RECORD_FILE_PREFIX}//")

            local typed_data
            typed_data=$(cat "$record_file")
            local data_type
            data_type=$(get_value_type "$typed_data")


            create_index "$collection_name" "id" "$record_id" "$record_file"
            create_index "$collection_name" "type" "$data_type" "$record_file"
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

    local query_id
    query_id=$(submit_async_query "$query")
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

    local status
    status=$(check_async_query_status "$query_id")
    echo "Async query status: $status"
}

function get_async_query() {
    local query_id="$1"
    if [[ -z "$query_id" ]]; then
        handle_error "Query ID is required" 1
    fi

    local result
    result=$(get_async_query_result "$query_id")
    echo "Async query result: $result"
}

function query_data() {
    local query="$1"
    local page="${2:-1}"
    local limit="${3:-10}"

    if [[ -z "$query" ]]; then
        handle_error "Query is required" 1
    fi

    local result
    result=$(perform_query "$query" "$page" "$limit")
    if [[ $? -ne 0 ]]; then
        handle_error "Failed to query data: $query" 1
    fi

    echo "Query result:"
    echo "$result"
}

while [[ $# -gt 0 ]]; do 
    case "$1" in
        --create-record)
            collection="$2"
            data="$3"
            data_type="$4"
            transaction_id="$5"
            if [[ -z "$collection" || -z "$data" || -z "$data_type" ]]; then
                handle_error "Usage: --create-record <collection> <data> <data_type> [transaction_id]" 1
            fi
            created_id="$(create_record "$collection" "$data" "$data_type" "$transaction_id")"
            echo "New record created with ID: $created_id"
            if [[ -n "$transaction_id" ]]; then
                shift 5
            else
                shift 4
            fi
            ;;
        --query)
            shift
            query="$1"
            if [[ -z "$query" ]]; then
                handle_error "Usage: --query \"<query>\"" 1
            fi
            perform_query "$query"
            shift
            ;;
        --async-query)
            shift
            query="$1"
            if [[ -z "$query" ]]; then
                handle_error "Usage: --async-query \"<query>\"" 1
            fi
            submit_async_query "$query"
            shift
            ;;
        --check-async-query)
            shift
            query_id="$1"
            if [[ -z "$query_id" ]]; then
                handle_error "Usage: --check-async-query <query_id>" 1
            fi
            check_async_query "$query_id"
            shift
            ;;
        --get-async-query)
            shift
            query_id="$1"
            if [[ -z "$query_id" ]]; then
                handle_error "Usage: --get-async-query <query_id>" 1
            fi
            get_async_query "$query_id"
            shift
            ;;
        --begin-transaction)
            shift
            txn_id="$1"
            if [[ -z "$txn_id" ]]; then
                handle_error "Usage: --begin-transaction <transaction_id>" 1
            fi
            begin_transaction "$txn_id"
            shift
            ;;
        --commit-transaction)
            shift
            txn_id="$1"
            if [[ -z "$txn_id" ]]; then
                handle_error "Usage: --commit-transaction <transaction_id>" 1
            fi
            commit_transaction "$txn_id"
            shift
            ;;
        --rollback-transaction)
            shift
            txn_id="$1"
            if [[ -z "$txn_id" ]]; then
                handle_error "Usage: --rollback-transaction <transaction_id>" 1
            fi
            rollback_transaction "$txn_id"
            shift
            ;;
        --backup)
            shift
            backup_name="$1"
            backup_data "$backup_name"
            shift
            ;;
        --restore)
            shift
            backup_name="$1"
            restore_data "$backup_name"
            shift
            ;;
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
done

load_collections