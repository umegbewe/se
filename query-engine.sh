#!/bin/bash

function evaluate_conditions() {
    local data="$1"
    local data_type="$2"
    local conditions="$3"

    IFS='|' read -ra condition_array <<< "$conditions"
    for condition in "${condition_array[@]}"; do
        if [[ "$condition" =~ ([^=<>]+)([=<>]+)(.*) ]]; then
            local field="${BASH_REMATCH[1]}"
            local operator="${BASH_REMATCH[2]}"
            local value="${BASH_REMATCH[3]}"

            # Remove leading/trailing whitespace from field, operator, and value
            field=$(echo "$field" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            operator=$(echo "$operator" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Remove quotes from the value if present
            value=$(echo "$value" | sed "s/^['\"]//;s/['\"]$//")

            case "$operator" in
                "=")
                if [[ "$data" != "$value" ]]; then
                        return 1
                fi
                ;;
            ">" )
                if ! is_numeric "$data" || ! is_numeric "$value" || (( $(echo "$data <= value" | bc -l) )); then
                    return 1
                fi
                ;;
            "<" )
                if ! is_numeric "$data" || ! is_numeric "$value" || (( $(echo "$data >= value" | bc -l) )); then
                    return 1
                fi
                ;;
            ">=" )
                if ! is_numeric "$data" || ! is_numeric "$value" || (( $(echo "$data < value" | bc -l) )); then
                    return 1
                fi
                ;;
            "<=" )
                if ! is_numeric "$data" || ! is_numeric "$value" || (( $(echo "$data > value" | bc -l) )); then
                    return 1
                fi
                ;;
            * )
                echo "Invalid operator: $operator"
                return 1
            ;;
        esac
        else
            echo "Invalid condition: $condition"
            return 1
        fi
    done
    return 0
}

function is_numeric() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

function execute_query() {
    local parsed_query="$1"
    local offset="$2"
    local limit="$3"

    local collection=$(echo "$parsed_query" | grep "Collection:" | cut -d' ' -f2)
    local conditions=$(echo "$parsed_query" | grep "Conditions:" | cut -d' ' -f2-)
    local order_by=$(echo "$parsed_query" | grep "Order By:" | cut -d' ' -f3-)

    local indexed_fields=$(get_indexed_fields "$collection")

    local record_files=""
    for condition in $conditions; do
        if [[ "$condition" =~ ([^=<>]+)([=<>]+)(.*) ]]; then
            local field="${BASH_REMATCH[1]}"
            local operator="${BASH_REMATCH[2]}"
            local value="${BASH_REMATCH[3]}"

            field=$(echo "$field" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            operator=$(echo "$operator" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed "s/^['\"]//;s/['\"]$//")

            if [[ " $indexed_fields " == *" $field "* ]]; then
                local index_file="${DATA_DIR}/${collection}/indexes/${field}"
                local matching_files=$(grep "^$value:" "$index_file" | cut -d':' -f2-)
                record_files+=" $matching_files"
            fi
        fi
    done

    if [[ -z "$record_files" ]]; then
        record_files=$(find "$DATA_DIR/$collection" -type f -name "${RECORD_FILE_PREFIX}*")
    fi

    local filtered_records=""
    for record_file in $record_files; do
        local record_data=$(cat "$record_file")
        local data=$(get_data "$record_data")
        local data_type=$(get_value_type "$record_data")

        if evaluate_conditions "$data" "$data_type" "$conditions"; then
            filtered_records+="$data|$data_type\n"
        fi
    done

    if [[ -n "$order_by" ]]; then
        local order_field=$(echo "$order_by" | cut -d' ' -f1)
        local order_direction=$(echo "$order_by" | cut -d' ' -f2)
        filtered_records=$(echo -e "$filtered_records" | sort -t'|' -k1)
        if [[ "$order_direction" == "DESC" ]]; then
            filtered_records=$(echo "$filtered_records" | tac)
        fi
    fi

    local paginated_records=$(echo "$filtered_records" | tail -n +$((offset + 1)) | head -n "$limit")

    echo -e "$paginated_records"
}

function perform_query() {
    local query="$1"
    local page=${2:-1}
    local limit=${3:-10}

    local cached_result=$(get_cached_query_result "$query:$page:$limit")
    if [[ -n "$cached_result" ]]; then
        echo "$cached_result"
        return
    fi

    local parsed_query=$(parse_query "$query")
    local optimized_query=$(optimize_query "$parsed_query")

    local offset=$(((page - 1) * limit))
    local result=$(execute_query "$optimized_query" "$offset" "$limit")

    cache_query_result "$query:$page:$limit" "$result"

    echo "$result"
}
