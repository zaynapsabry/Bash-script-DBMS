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
        # echo "dir is empty"
        return 0 #true
    else
        # echo "dir not empty"
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
    local tablename=$1
    local col_value=$2
    local column_number=$3 

    local col_type
    col_type=$(awk -F: -v col="$column_number" '
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
        }' ".$tablename-metadata.txt")

    if [[ "$col_type" == "int" ]]; then
        if ! [[ "$col_value" =~ ^[0-9]+$ ]]; then
            echo -e "\e[31mError:\e[0m The value of the column should be an integer." >&2
            echo "" >&2
            return 1
        fi
        
    elif [[ "$col_type" == "string" ]]; then
        if ! [[ "$col_value" =~ ^[a-zA-Z]+$ ]]; then
            echo -e "\e[31mError:\e[0m The value of the column should be a string." >&2
            echo "" >&2
            return 1
        fi
    fi
    return 0
}

function validate_col_constraint_value_input_match {
    local tablename=$1
    local column_value=$2
    local column_number=$3

    local not_null_columns=($(get_not_null_columns "$tablename"))
    local unique_columns=($(get_unique_columns "$tablename"))
    local pk_field_number=$(get_primary_key_number "$tablename")
    
    for not_null_column in "${not_null_columns[@]}"; do
        if (($column_number == $not_null_column)); then
            if [[ "$column_value" =~ ^([nN][uU][lL]{2}|)$ ]]; then
                echo -e "\e[31mError:\e[0m The value of the column should not be empty." >&2
                echo "" >&2
                return 1
            fi
        fi
    done

    for unique_column in "${unique_columns[@]}"; do
        if (($column_number == $unique_column)); then
            local unique_column_values
            unique_column_values=$(awk -F: -v col="$column_number" 'NR>=1 {print $col}' "$tablename")
            if [[ "$unique_column_values" =~ $column_value ]]; then
                echo -e "\e[31mError:\e[0m The value of the column should be unique." >&2
                echo "" >&2
                return 1
            fi
        fi
    done

    if (($column_number == $pk_field_number)); then
        local pk_column_values
        pk_column_values=$(awk -F: -v col="$column_number" 'NR>=1 {print $col}' "$tablename")
        if [[ "$pk_column_values" =~ $column_value ]] && [[ ! "$column_value" =~ ^([nN][uU][lL]{2}|)$ ]]; then
            echo -e "\e[31mError:\e[0m The value of the column should be unique and not null." >&2
            echo "" >&2
            return 1
        fi
    fi

    return 0
}

function get_primary_key_number {
    local tablename=$1

    local pk_field_number=$(awk -F: '
        BEGIN { found=0 }
        NR==3 {
            split($0, primary_keys)
            for (i = 1; i <= NF; i++) {
                if (primary_keys[i] == "primarykey") {
                    pk_field_number = i
                    found = 1
                    break
                }
            }
        }
        END {
            if (found == 1) {
                print pk_field_number
            }
        }' ".$tablename-metadata.txt")
    echo "$pk_field_number"
}

function get_not_null_columns {
    local tablename=$1
    local not_null_columns=($(awk -F: '
        BEGIN { found=0 }
        NR==3 {
            split($0, not_nulls)
            for (i = 1; i <= NF; i++) {
                if (not_nulls[i] == "notnull") {
                    not_null_columns[i] = i
                    found = 1
                }
            }
        }
        END {
            if (found == 1) {
                for (i in not_null_columns) {
                    printf "%s ", i
                }
            }
        }' ".$tablename-metadata.txt"))
    echo "${not_null_columns[@]}"
}

function get_unique_columns {
    local tablename=$1
    local unique_columns=($(awk -F: '
        BEGIN { found=0 }
        NR==3{
            split($0, uniques)
            for (i = 1; i <= NF; i++) {
                if (uniques[i] == "unique") {
                    unique_columns[i] = i
                    found = 1
                }
            }
        }
        END {
            if (found == 1) {
                for (i in unique_columns) {
                    printf "%s ", i
                }
            }
        }' ".$tablename-metadata.txt"))
    echo "${unique_columns[@]}"
}

function get_field_values {
    local tablename=$1
    local column_num=$2

    local column_values=($(awk -F: -v col="$column_num" 'NR>=1 {print $col}' "$tablename"))

    echo "${column_values[@]}"
}
