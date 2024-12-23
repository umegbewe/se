#!/bin/bash

function evaluate_condition() {
    local field="$1"       # "name"
    local operator="$2"    # "LIKE", "=", ">", ">=", etc.
    local value="$3"       # "John%", 25, "jane@example.com"
    local record_data="$4" # some representation of record

    declare -A record_map=()
    parse_record_into_map "$record_data" record_map

    local field_value="${record_map["value"]}"

    # if the field doesn’t exist in the record, skip or fail
    if [[ -z "$field_value" && "$field_value" != 0 ]]; then
        echo "false"
        return
    fi

    case "$operator" in
        "=")
             if [[ "${field_value}" = "${value}" ]]; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "!=")
            if [[ "$field_value" != "$value" ]]; then echo "true"; else echo "false"; fi
            ;;
        "<")
            if (( field_value < value )); then echo "true"; else echo "false"; fi
            ;;
        "<=")
            if (( field_value <= value )); then echo "true"; else echo "false"; fi
            ;;
        ">")
            if (( field_value > value )); then echo "true"; else echo "false"; fi
            ;;
        ">=")
            if (( field_value >= value )); then echo "true"; else echo "false"; fi
            ;;
        "LIKE")
            # turn % into .* for a regex
            local pattern
            pattern=$(echo "$value" | sed 's/%/.*/g')
            if [[ "$field_value" =~ ^$pattern$ ]]; then 
                echo "true" 
            else 
                echo "false" 
            fi
            ;;
        *)
            echo "false"
            ;;
    esac
}

function parse_record_into_map() {
    local record_data="$1"
    local -n out_map="$2"
    
    local key val
    IFS='|' read -r key val <<< "$record_data"
    out_map["value"]="$key"
    out_map["type"]="$val"
}

function evaluate_logic() {
    local expr="$1"
    local record_data="$2"

    expr="$(echo "$expr" | sed -E 's/^[[:space:]]*\((.*)\)[[:space:]]*$/\1/')"

    local top_operator=""
    local left_expr=""
    local right_expr=""
    local paren_level=0
    local i
    local -i len=${#expr}

    for (( i=0; i<len; i++ )); do
        local c="${expr:$i:1}"
        if [[ "$c" == "(" ]]; then
            ((paren_level++))
        elif [[ "$c" == ")" ]]; then
            ((paren_level--))
        elif ((paren_level == 0)); then
            # check for "AND " or "OR "
            if [[ "${expr:$i:4}" == "AND " || "${expr:$i:3}" == "AND" ]]; then
                top_operator="AND"
                left_expr="${expr:0:$i}"
                right_expr="${expr:$((i+3))}"
                break
            elif [[ "${expr:$i:3}" == "OR " || "${expr:$i:2}" == "OR" ]]; then
                top_operator="OR"
                left_expr="${expr:0:$i}"
                right_expr="${expr:$((i+2))}"
                break
            fi
        fi
    done

    if [[ -n "$top_operator" ]]; then
        # aND or OR at top level
        left_expr="$(echo "$left_expr" | xargs)"   # trim
        right_expr="$(echo "$right_expr" | xargs)" # trim
        local left_val
        left_val=$(evaluate_logic "$left_expr" "$record_data")
        local right_val
        right_val=$(evaluate_logic "$right_expr" "$record_data")

        if [[ "$top_operator" == "AND" ]]; then
            if [[ "$left_val" == "true" && "$right_val" == "true" ]]; then
                echo "true"
            else
                echo "false"
            fi
        else
            # OR
            if [[ "$left_val" == "true" || "$right_val" == "true" ]]; then
                echo "true"
            else
                echo "false"
            fi
        fi
    else
        if [[ "$expr" =~ ^\(.+\)$ ]]; then
            local sub_expr="${expr:1:$((${#expr}-2))}"
            echo "$(evaluate_logic "$sub_expr" "$record_data")"
        else
            local field operator raw_value
            if [[ "$expr" =~ ^([^[:space:]]+)[[:space:]]+([=!<>]+|LIKE)[[:space:]]+(.+)$ ]]; then
                field="${BASH_REMATCH[1]}"
                operator="${BASH_REMATCH[2]}"
                raw_value="${BASH_REMATCH[3]}"
                value=$(printf '%b' "$(echo "$raw_value" | sed -E 's/^'\''//; s/'\''$//; s/'\''\\'\'\''/'\''/')")
                local ret
                ret=$(evaluate_condition "$field" "$operator" "$value" "$record_data")
                echo "$ret"
            else
                echo "false"
            fi
        fi
    fi
}

function is_numeric() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

function perform_query() {
    local query="$1"

    local parsed
    parsed="$(parse_query "$query")"

    local collection
    collection="$(echo "$parsed" | grep '^collection=' | cut -d= -f2-)"
    local conditions
    conditions="$(echo "$parsed" | grep '^conditions=' | cut -d= -f2-)"
    local order_by
    order_by="$(echo "$parsed" | grep '^order_by=' | cut -d= -f2-)"
    local limit_value
    limit_value="$(echo "$parsed" | grep '^limit_value=' | cut -d= -f2-)"

    [[ -z "$collection" ]] && return 0

    local coll_dir="${DATA_DIR}/${collection}"
    [[ ! -d "$coll_dir" ]] && return 0

    local result_records=()
    local record_file
    for record_file in "$coll_dir"/record_*; do
        [[ -f "$record_file" ]] || continue
        local record_data
        record_data="$(cat "$record_file")"

        if [[ -z "$conditions" ]]; then
            # no conditions => match everything
            result_records+=( "$record_file" )
        else
            local is_match
            is_match="$(evaluate_logic "$conditions" "$record_data")"
            if [[ "$is_match" == "true" ]]; then
                result_records+=( "$record_file" )
            fi
        fi
    done


    if [[ -n "$order_by" ]]; then
        local sort_field
        local sort_dir
        sort_field="$(echo "$order_by" | awk '{print $1}')"
        sort_dir="$(echo "$order_by" | awk '{print toupper($2)}')"

        local sort_buffer
        sort_buffer="$(mktemp)"
        for f in "${result_records[@]}"; do
            local tmp_data
            tmp_data="$(cat "$f")"
            declare -A tmp_map=()
            parse_record_into_map "$tmp_data" tmp_map
            local key_val
            key_val="${tmp_map[$sort_field]}"
            echo "$key_val|$f" >> "$sort_buffer"
        done

        if [[ "$sort_dir" == "DESC" ]]; then
            result_records=( $(sort -r -t'|' -k1 "$sort_buffer" | cut -d'|' -f2-) )
        else
            result_records=( $(sort -t'|' -k1 "$sort_buffer" | cut -d'|' -f2-) )
        fi

        rm -f "$sort_buffer"
    fi

    if [[ -n "$limit_value" ]]; then
        local new_array=()
        local count=0
        for f in "${result_records[@]}"; do
            new_array+=( "$f" )
            ((count++))
            if (( count >= limit_value )); then
                break
            fi
        done
        result_records=( "${new_array[@]}" )
    fi

    for f in "${result_records[@]}"; do
        echo "$(cat "$f")"
    done
}