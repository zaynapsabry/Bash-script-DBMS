#!/bin/bash

function directory_exists {
  if [ -d $1 ]; then
    return 0 #true
  else
    return 1 #false
  fi
}

function file_exists {
  if [ -f $1 ]; then
    return 0 #true
  else
    return 1 #false
  fi
}

function validate_name {
    local name=$1
    # Database name is empty #used "" to prevent issue with spacing 
    if [ -z "$name" ]; then
        echo "Database name is required"
        return 1
    # Check if name contains any spaces
    elif [[ "$name" =~ [[:space:]] ]]; then
        echo "Name contains spaces"
        return 1
    # Check for invalid characters
    elif [[ "$name" =~ [^a-zA-Z0-9_] ]]; then
        echo "Database name contains invalid characters"
        return 1
    # Check if name exceeds 64 characters
    elif [ ${#name} -gt 64 ]; then
        echo "Database name is too long"
        return 1
    # Check if name starts with a number
    elif [[ "$name" =~ ^[0-9] ]]; then
        echo "Name starts with a number"
        return 1
    else
        echo "Database name is valid"
        return 0
    fi
}

validate_db_name "hugy_d"


