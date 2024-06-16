function create_index() {
    local collection="$1"
    local record_id="$2"
    local record_file="$3"

    local index_file="${DATA_DIR}/${collection}/index"

    mkdir -p "${DATA_DIR}/${collection}" || handle_error "Failed to create collection directory: ${DATA_DIR}/${collection}" 1
    echo "$record_id:$record_file" >> "$index_file" || handle_error "Failed to create index entry: $record_id" 1
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