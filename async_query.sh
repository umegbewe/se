#!/bin/bash

function submit_async_query() {
    local query="$1"
    local timestamp
    timestamp=$(date +%s%N)
    local random_num=$RANDOM
    local query_id="${timestamp}_${random_num}"

    mkdir -p "${DATA_DIR}/async_queries" || {
        echo "Error: Could not create 'async_queries' directory."
        return 1
    }

    echo "$query" > "${DATA_DIR}/async_queries/${query_id}.query"

    nohup bash -c "
        bash storage-engine.sh --query \"$query\" > \"${DATA_DIR}/async_queries/${query_id}.result\" 2>&1
        echo \$? > \"${DATA_DIR}/async_queries/${query_id}.status\"
    " >/dev/null 2>&1 &

    echo "$query_id"
}


function check_async_query_status() {
    local query_id="$1"
    local status_file="${DATA_DIR}/async_queries/${query_id}.status"

    if [[ ! -f "$status_file" ]]; then
        echo "RUNNING"
        return
    fi

    local exit_code
    exit_code="$(cat "$status_file")"

    if [[ "$exit_code" -eq 0 ]]; then
        echo "COMPLETE"
    else
        echo "FAILED (exit code $exit_code)"
    fi
}


function get_async_query_result() {
    local query_id="$1"
    local result_file="${DATA_DIR}/async_queries/${query_id}.result"
    local status_file="${DATA_DIR}/async_queries/${query_id}.status"

    if [[ ! -f "$result_file" ]]; then
        echo "Error: No async query result file found for ID: $query_id"
        return 1
    fi
    if [[ ! -f "$status_file" ]]; then
        echo "Error: Query $query_id is still running or missing status."
        return 2
    fi

    cat "$result_file"
}