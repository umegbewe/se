#!/bin/bash

function parse_query() {
    local query="$1"

    local collection
    collection=$(echo "$query" | awk 'BEGIN{FS=" "} { for(i=1;i<=NF;i++){ if($i=="FROM") print $(i+1) } }')
    local conditions
    conditions=$(
        echo "$query" \
        | sed -n -e '/WHERE/ {
            s/.*WHERE //; 
            s/[[:space:]]ORDER BY.*//; 
            s/[[:space:]]LIMIT.*//; 
            p;
        }'
    )
    local order_by
    order_by=$(
        echo "$query" \
        | sed -n -e '/ORDER BY/ {
            s/.*ORDER BY *//;
            s/[[:space:]]LIMIT.*//;
            p;
        }'
    )
    local limit_value
    limit_value=$(
        echo "$query" \
        | sed -n -e '/LIMIT/ {
            s/.*LIMIT *//;
            p;
        }'
    )

    echo "collection=$collection"
    echo "conditions=$conditions"
    echo "order_by=$order_by"
    echo "limit_value=$limit_value"
}
