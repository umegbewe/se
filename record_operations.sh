#!/bin/bash

function create_record() {
    local collection="$1"
    local data="$2"
    local data_type="$3"
    local transaction_id="$4"

    validate_data "$data" "$data_type"

    local timestamp
    timestamp=$(date +%s%N)
    local random_num=$RANDOM
    local record_id="${timestamp}_${random_num}"
    local record_file="${DATA_DIR}/${collection}/${RECORD_FILE_PREFIX}${record_id}"

    mkdir -p "${DATA_DIR}/${collection}" \
      || handle_error "Failed to create table directory: ${DATA_DIR}/${collection}" 1

    [[ -e "$record_file" ]] && handle_error "Record file already exists: $record_file" 1

    local typed_data
    typed_data=$(set_type "$data" "$data_type")

    if [[ -n "$transaction_id" ]]; then
        local transaction_dir="${DATA_DIR}/transactions/${transaction_id}"
        mkdir -p "$transaction_dir" || handle_error "Failed to create transaction directory: $transaction_dir" 1
        echo "$typed_data" > "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}"
        log_transaction "$transaction_id" "create" "$collection" "$record_id"
    else 
        echo "$typed_data" > "$record_file" \
          || handle_error "Failed to create record file: $record_file"
        create_index "$collection" "id" "$record_id" "$record_file"
        create_index "$collection" "type" "$data_type" "$record_file"
    fi

    echo "$record_id"
}
function read_record() {
    local collection="$1"
    local record_id="$2"
    local record_file="${DATA_DIR}/${collection}/${RECORD_FILE_PREFIX}${record_id}"

    [[ -z "$record_id" ]] && handle_error "No record ID provided" 1
    [[ ! -e "$record_file" ]] && handle_error "Record file does not exist: $record_file" 1

    local record_data
    record_data=$(cat "$record_file")
    local data
    data=$(get_data "$record_data")
    local data_type
    data_type=$(get_value_type "$record_data")

    echo "Data: $data"
    echo "Type: $data_type"
}

function update_record() {
    local collection="$1"
    local record_id="$2"
    local new_data="$3"
    local new_data_type="$4"
    local transaction_id="$5"

    local record_file="${DATA_DIR}/${collection}/${RECORD_FILE_PREFIX}${record_id}"
    local index_dir="${DATA_DIR}/${collection}/indexes"

    [[ -z "$record_id" ]] && handle_error "No record ID provided" 1
    [[ -z "$new_data" ]] && handle_error "No new data provided for updating the record" 1
    [[ ! -e "$record_file" ]] && handle_error "Record file does not exist: $record_file" 1

    validate_data "$new_data" "$new_data_type"

    local typed_data
    typed_data=$(set_type "$new_data" "$new_data_type")

    if [[ -n "$transaction_id" ]]; then
        local transaction_dir="${DATA_DIR}/transactions/${transaction_id}"
        mkdir -p "$transaction_dir"
        cp "$record_file" "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}.bak"
        echo "$typed_data" > "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}"
        log_transaction "$transaction_id" "update" "$collection" "$record_id"
    else
        echo "$typed_data" > "$record_file" \
            || handle_error "Failed to update record file: $record_file"

        local index_files
        index_files=$(find "$index_dir" -type f)
        for index_file in $index_files; do
            if grep -q "^$record_id:" "$index_file"; then
                # Do an in-place replace with a backup, then remove backup
                sed -i.bak "s|^$record_id:.*|$record_id:$record_file|" "$index_file" \
                  || handle_error "Failed to update index entry for record: $record_id" 1
                rm -f "${index_file}.bak"
            fi
        done
    fi

    echo "Record updated successfully with ID: $record_id"
}

function delete_record() {
    local collection="$1"
    local record_id="$2"
    local transaction_id="$3"

    local record_file="${DATA_DIR}/${collection}/${RECORD_FILE_PREFIX}${record_id}"
    local index_dir="${DATA_DIR}/${collection}/indexes"

    [[ -z "$record_id" ]] && handle_error "No record ID provided" 1
    [[ ! -e "$record_file" ]] && handle_error "Record file does not exist: $record_file" 1

    if [[ -n "$transaction_id" ]]; then
        local transaction_dir="${DATA_DIR}/transactions/${transaction_id}"
        mkdir -p "$transaction_dir"
        mv "$record_file" "${transaction_dir}/${RECORD_FILE_PREFIX}${record_id}"
        log_transaction "$transaction_id" "delete" "$collection" "$record_id"
    else
        rm "$record_file" || handle_error "Failed to delete record file: $record_file"
        local index_files
        index_files=$(find "$index_dir" -type f)
        for index_file in $index_files; do
            if grep -q "^$record_id:" "$index_file"; then
                sed -i.bak "/^$record_id:.*/d" "$index_file" \
                  || handle_error "Failed to delete index entry for record: $record_id" 1
                rm -f "${index_file}.bak"
            fi
        done
    fi

    echo "Record deleted successfully with ID: $record_id"
}