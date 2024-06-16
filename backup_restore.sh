#!/bin/bash

BACKUP_DIR="backup"

function create_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/${backup_name}"

    mkdir -p "$backup_path" || handle_error "Failed to create backup directory: $backup_path" 1

    tar -czf "${backup_path}.tar.gz" data || handle_error "Failed to create backup archive" 1

    echo "Backup created successfully: ${backup_path}.tar.gz"
}

function restore_backup() {
    local backup_name="$1"
    local backup_path="${BACKUP_DIR}/${backup_name}"


    [[ ! -f "${backup_path}.tar.gz" ]] && handle_error "Backup archive does not exist: ${backup_path}.tar.gz" 1

    tar -xvf "${backup_path}.tar.gz" || handle_error "Failed to extract backup archive" 1

    echo "Data restored successfully from backup: ${backup_path}.tar.gz"
}