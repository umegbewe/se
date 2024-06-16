function create_index() {
    local collection="$1"
    local field="$2"
    local value="$3"
    local record_file="$4"

    local index_dir="${DATA_DIR}/${collection}/indexes"
    mkdir -p "$index_dir" || handle_error "Failed to create index directory: $index_dir" 1

    local index_file="${index_dir}/${field}"

    echo "$value:$record_file" >> "$index_file" || handle_error "Failed to create index entry: $record_id" 1
}

function search_index() {
    local collection="$1"
    local record_id="$2"

    local index_file="${DATA_DIR}/${collection}/index"

    [[ ! -e "$index_file" ]] && handle_error "Index file does not exist: $index_file" 1
    
    local record_file=$(grep "^$record_id:" "$index_file" | cut -d':' -f2)

    [[ -z "$record_file" ]] && handle_error "Record not found in index: $record_id" 1

    echo "$record_file"
}

function get_indexed_fields() {
    local collection="$1"
    local index_dir="${DATA_DIR}/$collection/indexes"

    local indexed_fields=""
    for index_file in "$index_dir"/*; do
        local field=$(basename "$index_dir")
        indexed_fields+=" $field"
    done

    echo "$indexed_fields"
}