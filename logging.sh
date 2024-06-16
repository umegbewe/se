#!/bin/bash


LOG_FILE="engine.log"

# function log_message() {
#     local message="$1"
#     local log_level="${2:-INFO}"
#     local timestamp=$(date +"%Y-%m-%d %T")

#     echo "[$timestamp] [$log_level] $message" >> "$LOG_FILE"
# }

function log_message() {
    local message="$1"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

function log_error() {
    local message="$1"

    log_message "ERROR: $message"
}