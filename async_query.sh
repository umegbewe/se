function submit_async_query() {
    local query="$1"

    local async_dir="${DATA_DIR}/async"
    mkdir -p "$async_dir"

    local query_id=$(generate_uuid)
    local query_file="${async_dir}/${query_id}"

    echo "$query" > "$query_file"

    (
        local result=$(perform_query "$query")
        echo "$result" > "${async_dir}/$query_file.result"
    ) &

    echo "$query_id"
}


function check-async-query-status() {
    local query_id="$1"

    local async_dir="${DATA_DIR}/async"
    local result_file="${async_dir}/${query_id}.result"

    if [[ -f "$result_file" ]]; then
        echo "COMPLETED"
    else
        echo "RUNNING"
    fi
}

function get-async-query-result() {
    local query_id="$1"

    local async_dir="${DATA_DIR}/async"
    local result_file="${async_dir}/${query_id}.result"

    if [[ -f "$result_file" ]]; then
        cat "$result_file"
    else
        echo "Query result not available yet"
    fi
}