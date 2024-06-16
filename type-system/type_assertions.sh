#!/bin/bash

function assert_type() {
    local data="$1"
    local expected_type="$2"

    if ! validate_data "$data" "$expected_type"; then 
        handle_error "Assertion failed: Expected type '$expected_type', but got 'data'" 1
    fi
}


function assert_string() {
    local data="$1"
    assert_type "$data" "string"
}

function assert_non_empty_string() {
    local data="$1"
    assert_type "$data" "non_empty_string"
}


function assert_integer() {
    local data="$1"
    assert_type "$data" "integer"
}


function assert_positive_integer() {
    local data="$1"
    assert_type "$data" "positive_integer"
}

function assert_negative_integer() {
    local data="$1"
    assert_type "$data" "negative_integer"
}

function assert_float() {
    local data="$1"
    assert_type "$data" "float"
}

function assert_boolean() {
    local data="$1"
    assert_type "$data" "boolean"
}

function assert_array() {
    local data="$1"
    assert_type "$data" "array"
}

function assert_email() {
    local data="$1"
    assert_type "$data" "email"
}

function assert_url() {
    local data="$1"
    assert_type "$data" "url"
}

function assert_supported_type() {
    local data_type="$1"
    if ! is_supported_type "$data_type"; then 
        handle_error "Unsupported data type: $data_type" 1
    fi
}
