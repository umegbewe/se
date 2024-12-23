#!/bin/bash


function validate_data() {
    local data="$1"
    local data_type="$2"

    if ! is_supported_type "$data_type"; then 
        handle_error "Unsupported data type: $data_type" 1
    fi

    local pattern
    pattern=$(get_type_pattern "$data_type")

    if ! [[ "$data" =~ $pattern ]]; then 
        handle_error "Invalid data format for type '$data_type': $data" 1
    fi
}