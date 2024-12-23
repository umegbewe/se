#!/bin/bash

source "storage-engine.sh"

setup_test_data() {
    create_record "users" "John Doe" "string"
    create_record "users" "25" "integer"
    create_record "users" "Jane Smith" "string"
    create_record "users" "30" "integer"
    create_record "users" "Alice Johnson" "string"
    create_record "users" "35" "integer"
}

cleanup_test_data() {
    rm -rf "$DATA_DIR"
}

test_simple_query() {
    local query="SELECT * FROM users WHERE name = 'John Doe'"
    local expected_output="John Doe|string"

    local result
    result=$(perform_query "$query")

   if echo "$result" | grep -q "John Doe|string"; then
        echo "Test passed: Simple query"
    else
        echo "Test failed: Simple query"
        echo "Expected: (at least a line with [John Doe|string])"
        echo "Actual: $result"
    fi
}

test_query_no_matching_records() {
    local query="SELECT * FROM users WHERE name = 'NonExistentUser'"
    local expected_output=""
    local result
    result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Query with no matching records"
    else
        echo "Test failed: Query with no matching records"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

test_query_multiple_matching_records() {
    rm -rf "${DATA_DIR}/users"
    create_record users "John Smith" string
    create_record users "John Doe" string
    
    local query="SELECT * FROM users WHERE name LIKE 'John%'"
    local expected_output="John Doe|string
John Smith|string"
    local result
    result=$(perform_query "$query")
    
    if [[ "$(echo "$result" | sort)" == "$(echo "$expected_output" | sort)" ]]; then
        echo "Test passed: Query with multiple matching records"
    else
        echo "Test failed: Query with multiple matching records"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

test_query_non_existent_field() {
    local query="SELECT * FROM users WHERE non_existent_field = 'value'"
    local expected_output=""
    local result
    result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Query with a non-existent field"
    else
        echo "Test failed: Query with a non-existent field"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

test_query_empty_collection() {
    local query="SELECT * FROM empty_collection WHERE name = 'John Doe'"
    local expected_output=""
    local result
    result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Query with an empty collection"
    else
        echo "Test failed: Query with an empty collection"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

test_query_special_characters() {
    create_record users "John O'Doe" string

    local query="SELECT * FROM users WHERE name = 'John O'\''Doe'"
    local expected_output="John O'Doe|string"
    local result
    result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Query with special characters in the field value"
    else
        echo "Test failed: Query with special characters in the field value"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

setup_test_data
test_simple_query
test_query_no_matching_records
test_query_multiple_matching_records
test_query_non_existent_field
test_query_empty_collection
test_query_special_characters
cleanup_test_data