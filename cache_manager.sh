#!/bin/bash

function cache_query_result() {
    local query="$1"
    local result="$2"

    local cache_dir="${DATA_DIR}/cache"

    mkdir -p "$cache_dir" || handle_error "Failed to create cache directory: $cache_dir" 1

    local cache_key
    cache_key=$(echo "$query" | md5sum | cut -d' ' -f1)
    local cache_file="${cache_dir}/$cache_key"

    echo "$result" > "$cache_file"
}


function get_cached_query_result() {
    local query="$1"

    local cache_dir="${DATA_DIR}/cache"
    local cache_key
    cache_key=$(echo "$query" | md5sum | cut -d' ' -f1)
    local cache_file="${cache_dir}/$cache_key"

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    else
        return 1
    fi

}

function clear_cache() {
    local cache_dir="${DATA_DIR}/cache"
    rm -rf "$cache_dir"
}