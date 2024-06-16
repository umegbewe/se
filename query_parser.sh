function parse_query() {
    local query="$1"
    
    local collection=$(echo "$query" | awk '{print $4}')
    local conditions=$(echo "$query" | sed -n '/WHERE/,/ORDER BY/p' | sed '1d;$d' | tr '\n' '|')
    local order_by=$(echo "$query" | sed -n '/ORDER BY/p' | cut -d' ' -f3-)
    local limit=$(echo "$query" | sed -n '/LIMIT/p' | cut -d' ' -f2)

    echo "Collection: $collection"
    echo "Conditions: $conditions"
    echo "Order by: $order_by"
    echo "Limit: $limit"
}

function optimize_query() {
    local parsed_query="$1"

    local conditions=$(echo "$parsed_query" | grep "Conditions:" | cut -d' ' -f2-)
    local optimized_conditions=""

    IFS='|' read -ra conditions_array <<< "$conditions"
    for condition in "${conditions_array[@]}"; do
        local field=$(echo "$condition" | cut -d' ' -f1)
        local operator=$(echo "$condition" | cut -d' ' -f2)
        local value=$(echo "$condition" | cut -d' ' -f3-)

        if [[ "$operator" == "=" ]]; then
            optimized_conditions+="$field $operator $value|"
        elif [[ "$operator" == ">" || "$operator" == "<" || "$operator" == ">=" || "$operator" == "<=" ]]; then
            optimized_conditions+="$field $operator $value|"
        else 
            optimized_conditions+="$condition|"
        fi
    done

    echo "$parsed_query" | sed "s/Conditions:.*$/Conditions: ${optimized_conditions%|}/g"
}
