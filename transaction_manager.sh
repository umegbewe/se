#!/bin/bash

function generate_transaction_id() {
    echo "$(date +%s%N)_$$"
}

function begin_transaction() {
    local transaction_id
    transaction_id=$(generate_transaction_id)
    mkdir -p "${DATA_DIR}/transactions/${transaction_id}"

    echo "$transaction_id"
}

function log_transaction() {
    local transaction_id="$1"
    local operation="$2"
    local collection="$3"
    local record_id="$4"

    echo "${operation}:${collection}:${record_id}" >> "${DATA_DIR}/transactions/${transaction_id}/log"
}

function commit_transaction() {
    local transaction_id="$1"
    local transaction_dir="${DATA_DIR}/transactions/${transaction_id}"

    # move records from transaction directory to data directory
    while IFS= read -r record_log; do 
        local operation
        operation=$(echo "$record_log" | cut -d':' -f1)
        local collection
        collection=$(echo "$record_log" | cut -d':' -f2)
        local record_id
        record_id=$(echo "$record_log" | cut -d':' -f3)

        case "$operation" in
            "create")
                mv "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}" "${DATA_DIR}/${collection}/" \
                    || handle_error "Failed to commit 'create' operation for record: [$record_id] in collection: [$collection]" 1
                ;;
            "update")
                mv "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}" "${DATA_DIR}/${collection}/" \
                    || handle_error "Failed to commit 'update' operation for record: [$record_id] in collection: [$collection]" 1
                ;;
            "delete")
               mv "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}" "${DATA_DIR}/${collection}/" \
                  || handle_error "Failed to commit 'delete' operation for record ${record_id}" 1
                ;;
            *)
                handle_error "Invalid operation in transaction log: $operation" 1
                ;;
        esac
    done < "$transaction_dir/log"

    rm -rf "$transaction_dir"
}

function rollback_transaction() {
    local transaction_id="$1"
    local transaction_dir="${DATA_DIR}/transactions/${transaction_id}"

    # revert changes done by transaction
    while IFS= read -r record_log; do 
        local operation
        operation=$(echo "$record_log" | cut -d':' -f1)
        local collection
        collection=$(echo "$record_log" | cut -d':' -f2)
        local record_id
        record_id=$(echo "$record_log" | cut -d':' -f3)

        case "$operation" in
            "create")
                rm -f "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}"
                ;;
            "update")
                mv "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}.bak" \
                   "${DATA_DIR}/${collection}/${RECORD_FILE_PREFIX}${record_id}" \
                   || handle_error "Failed to rollback 'update' operation for record ${record_id}" 1
                ;;
            "delete")
                mv "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}" \
                   "${DATA_DIR}/${collection}/${RECORD_FILE_PREFIX}${record_id}" \
                   || handle_error "Failed to rollback 'delete' operation for record ${record_id}" 1
                ;;
            *)
                handle_error "Invalid operation in transaction log: $operation" 1
                ;;
        esac
    done < "$transaction_dir/log"

    rm -rf "$transaction_dir"
}