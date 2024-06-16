#!/bin/bash

DATA_DIR="data"
RECORD_FILE_PREFIX="record_"

source "errors.sh"
source "index_operations.sh"
source "record_operations.sh"
source "type-system/type_definitions.sh"
source "type-system/type_validation.sh"
source "type-system/type_utils.sh"

mkdir -p "$DATA_DIR"
