#!/bin/bash

declare -A DATA_TYPES=(
  ["string"]="^.*$"
  ["non_empty_string"]="^.+$"
  ["integer"]="^[0-9]+$"
  ["positive_integer"]="^[1-9][0-9]*$"
  ["negative_integer"]="^-[1-9][0-9]*$"
  ["float"]="^[+-]?([0-9]*[.])?[0-9]+$"
  ["boolean"]="^(true|false)$"
  ["array"]="^(\[.*\])?$"
  ["email"]="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
  ["url"]="^(https?://)?([a-zA-Z0-9]+\.)+[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$"
)

function is_supported_type() {
  local data_type="$1"
  [[ -n "${DATA_TYPES[$data_type]}" ]]
}

function get_type_pattern() {
  local data_type="$1"
  echo "${DATA_TYPES[$data_type]}"
}
