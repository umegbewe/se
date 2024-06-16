#!/bin/bash

# Source the necessary scripts
source "errors.sh"
source "type-system/type_definitions.sh"
source "type-system/type_validation.sh"
source "type-system/type_assertions.sh"
source "type-system/type_utils.sh"

# Test type validation
validate_data "Hello, World!" "string"
validate_data "42" "integer"
validate_data "3.14" "float"
validate_data "true" "boolean"
validate_data "[1, 2, 3]" "array"
validate_data "john@example.com" "email"
validate_data "https://www.example.com" "url"

# Test type assertions
assert_string "Hello, World!"
assert_non_empty_string "Not empty"
assert_integer "42"

# Test type utilities
typed_value=$(set_type "Hello, World!" "string")
data=$(get_data "$typed_value")
value_type=$(get_value_type "$typed_value")
echo "Data: $data"
echo "Type: $value_type"

unknown_type=$(get_type "Some unknown value")
echo "Unknown type: $unknown_type"