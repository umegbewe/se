#!/bin/bash

function handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"

    echo "Error: $error_message"
    exit "$exit_code"
}