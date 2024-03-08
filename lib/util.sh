#!/bin/bash
database_path="../database"

function directory_exists {
    if [ -d "$1" ]; then
        return 0 #true
    else
        return 1 #false
    fi
}

function file_exists {
    if [ -f "$1" ]; then
        return 0 #true
    else
        return 1 #false
    fi
}

function file_empty {
    if [ -s "$1" ]; then
        return 0 #true
    else
        return 1 #false
    fi
}

function directory_empty {
    if [ -z "$(ls -A "$1")" ]; then
        echo "dir is empty"
        return 0 #true
    else
        echo "dir not empty"
        return 1 #false
    fi
}

function validate_name {
    local name=$1
    # Database name is empty #used "" to prevent issue with spacing
    if [ -z "$name" ]; then
        echo -e "\e[31mWarning:\e[0m Name is required"
        return 1
    # Check if name contains any spaces
    elif [[ "$name" =~ [[:space:]] ]]; then
        echo -e "\e[31mWarning:\e[0m Name cannot contain spaces"
        return 1
    # Check for invalid characters
    elif [[ "$name" =~ [^a-zA-Z0-9_] ]]; then
        echo -e "\e[31mWarning:\e[0m Name contains invalid characters"
        return 1
    # Check if name exceeds 64 characters
    elif [ ${#name} -gt 64 ]; then
        echo -e "\e[31mWarning:\e[0m Name is too long"
        return 1
    # Check if name starts with a number
    elif [[ "$name" =~ ^[0-9] ]]; then
        echo -e "\e[31mWarning:\e[0m Name cannot start with a number"
        return 1
    else
        echo -e "The name is \e[32mvalid:\e[0m"
        return 0
    fi
}

function validate_num() {
    local num=$1
    if [[ "$num" =~ ^[0-9]+$ ]]; then
        return 0
    elif [ -z "$num" ]; then
        echo -e "\e[31mWarning:\e[0m Number is required"
        return 1
    else
        echo -e "\e[31mWarning:\e[0m Invalid number"
        return 1
    fi

}


function validate_col_type_value_input {
    local col_value=$1
    local tablename=$2
    local column=$3
    # local dbname=$4

    local col_type=$(awk -F: -v col="$column" '
        BEGIN { found=0 }
        NR==2 {
            split($0, types)
            col_type = types[col]
            found=1
        }
        END {
            if (found == 1) {
                print col_type
            }
        }' "$tablename-metadata.txt")

    # echo "$col_type"    

    if [[ -z "$col_type" ]]; then
        echo "Column '$column' not found in metadata."
        return 1
    fi

    if [[ "$col_type" == "int" ]]; then
        if ! [[ "$col_value" =~ ^[0-9]+$ ]]; then
            echo -e "\e[31mError:\e[0m The value of the column should be an integer."
            return 1
        fi
    elif [[ "$col_type" == "string" ]]; then
        if ! [[ "$col_value" =~ ^[a-zA-Z]+$ ]]; then
            echo -e "\e[31mError:\e[0m The value of the column should be a string."
            return 1
        fi
    fi
    return 0
}
