#!/bin/bash

# Source the storage engine script
source "storage-engine.sh"

# Test the functions
collection="users"

record_id1=$(create_record "$collection" "John Doe" "string")
record_id2=$(create_record "$collection" "25" "integer")
record_id3=$(create_record "$collection" "true" "boolean")
record_id4=$(create_record "$collection" "john@example.com" "email")

echo "Created records with IDs: $record_id1, $record_id2, $record_id3, $record_id4"

read_record "$collection" "$record_id1"
update_record "$collection" "$record_id1" "John Doe Updated" "string"
delete_record "$collection" "$record_id2"

record_file=$(search_index "$collection" "$record_id3")
echo "Record file for ID $record_id3: $record_file"