#!/bin/bash


function get_type() {
    local data="$1"

    for type in "${!DATA_TYPES[@]}"; do
        if validate_data "$data" "$type" > /dev/null 2>&1; then
            echo "$type"
            return
        fi
    done

    echo "unknown type"
}


function set_type() {
    local data="$1"
    local type="$2"

    if ! is_supported_type "$type"; then
        handle_error "Invalid data type '$type'" 1
    fi

    echo "$data|$type"
}

function get_data() {
    local typed_value="$1"
    echo "$typed_value" | cut -d'|' -f1
}

function get_value_type() {
    local typed_value="$1"
    echo "$typed_value" | cut -d'|' -f2
}