#!/bin/bash


LOG_FILE="engine.log"

function log_message() {
    local message="$1"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

function log_error() {
    local message="$1"

    log_message "ERROR: $message"
}