#!/bin/bash


# Source the necessary files
source "storage-engine.sh"

# Set up test data
setup_test_data() {
    # create_collection "users"
    create_record "users" "John Doe" "string"
    create_record "users" "25" "integer"
    create_record "users" "Jane Smith" "string"
    create_record "users" "30" "integer"
    create_record "users" "Alice Johnson" "string"
    create_record "users" "35" "integer"
}

# Clean up test data
cleanup_test_data() {
    rm -rf "$DATA_DIR"
}

# Test case for simple query
test_simple_query() {
    local query="SELECT * FROM users WHERE name = 'John Doe'"
    local expected_output="John Doe|string"

    local result=$(perform_query "$query")

    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Simple query"
    else
        echo "Test failed: Simple query"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

test_query_no_matching_records() {
    local query="SELECT * FROM users WHERE name = 'NonExistentUser'"
    local expected_output=""
    local result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Query with no matching records"
    else
        echo "Test failed: Query with no matching records"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

test_query_multiple_matching_records() {
    create_record users "John Smith" string
    create_record users "John Doe" string
    
    local query="SELECT * FROM users WHERE name LIKE 'John%'"
    local expected_output="John Doe|string
John Smith|string"
    local result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
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
    local result=$(perform_query "$query")
    
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
    local result=$(perform_query "$query")
    
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
    
    local query="SELECT * FROM users WHERE name = 'John O\'Doe'"
    local expected_output="John O'Doe|string"
    local result=$(perform_query "$query")
    
    if [[ "$result" == "$expected_output" ]]; then
        echo "Test passed: Query with special characters in the field value"
    else
        echo "Test failed: Query with special characters in the field value"
        echo "Expected: $expected_output"
        echo "Actual: $result"
    fi
}

# Run the tests
setup_test_data
test_simple_query
test_query_no_matching_records
test_query_multiple_matching_records
test_query_non_existent_field
test_query_empty_collection
test_query_special_characters
cleanup_test_data

# # Test case for query with pagination
# test_query_with_pagination() {
#     local query="SELECT * FROM users ORDER BY age ASC"
#     local page=2
#     local limit=2
#     local expected_output="Jane Smith|string,30|integer"

#     local result=$(perform_query "$query" "$page" "$limit")

#     if [[ "$result" == "$expected_output" ]]; then
#         echo "Test passed: Query with pagination"
#     else
#         echo "Test failed: Query with pagination"
#         echo "Expected: $expected_output"
#         echo "Actual: $result"
#     fi
# }

# # Test case for cached query
# test_cached_query() {
#     local query="SELECT * FROM users WHERE age > 30"
#     local expected_output="Alice Johnson|string,35|integer"

#     # Execute the query once to cache the result
#     perform_query "$query"

#     # Retrieve the cached result
#     local result=$(get_cached_query_result "$query")

#     if [[ "$result" == "$expected_output" ]]; then
#         echo "Test passed: Cached query"
#     else
#         echo "Test failed: Cached query"
#         echo "Expected: $expected_output"
#         echo "Actual: $result"
#     fi
# }

# # Run the tests
# setup_test_data
# test_simple_query
# test_query_with_pagination
# test_cached_query
# cleanup_test_data