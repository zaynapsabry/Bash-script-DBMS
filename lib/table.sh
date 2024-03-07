#!/bin/bash

database_path="../databases"
# Function to select all data from the table
select_all_table_data() {
    local tablename=$1
    local dbname=$2
    # Print header
    awk 'BEGIN { FS=":"; color="\033[1;36m"; reset="\033[0m"; }
        NR==1 { 
        gsub(":", "    ");
        printf color $0 reset "\n";
     }' "$tablename"
    # echo "$(head -n 1 "$tablename" | tr ':' '\t')"

    # Print data, align columns nicely
    awk 'NR > 1 { gsub(":", "    "); print }' "$tablename"

    echo ""
}

# Function to select column data from the table
select_column_data() {
    local tablename=$1
    local field_number=$2
    local dbname=$3
    awk -F: -v col="$field_number" ' NR>1 {print $col}' "$tablename"
    echo "$column"
    echo ""
}

# Function to select row data from the table
select_row_data() {
    local tablename=$1
    local field_number=$2
    local column_value=$3
    local dbname=$4

    if validate_col_type_value_input "$column_value" "$tablename" "$field_number" "$dbname"; then

        # Use awk to iterate over each row in the file
        awk -F: -v field="$field_number" -v val="$column_value" 'BEGIN{OFS="\t";FS=":"}{
            if ($(field) == val) {
                print_found=1
                print
            }
        } END {
            if (!print_found) {
                print "\033[31mWarning:\033[0m\nNo data found"
            }
        }' "$tablename" 
        echo ""
        return 0
    else
        return 1
    fi
}


# Function to delete all data from the table
delete_all_table_data() {
    local tablename=$1
    local dbname=$2
    truncate --size 0 "$tablename"
    echo -e "All data in "$tablename" deleted\e[32msuccessfully\e[0m."
    echo ""
}

# Function to delete column data from the table
delete_column_data() {
    local tablename=$1
    local field_number=$2
    local dbname=$3
    # Use awk to print all columns except the specified one
    awk -F: -v col="$field_number" 'NR==1 { for (i=1; i<=NF; i++) if (i != col) printf "%s:", $i; printf "\n"; next } { for (i=1; i<=NF; i++) if (i != col) printf "%s:", $i; printf "\n" }' "$tablename" > "$tablename.tmp" && mv "$tablename.tmp" "$tablename"
    echo -e "All data in this column deleted \e[32msuccessfully\e[0m."
}

# Function to delete row data from the table
delete_row_data() {
    local tablename=$1
    local field_number=$2
    local column_value=$3
    local dbname=$4

    if validate_col_type_value_input "$column_value" "$tablename" "$field_number" "$dbname"; then

        # Use awk to iterate over each row in the file
        awk -F: -v field="$field_number" -v val="$column_value" 'BEGIN{OFS="\t";FS=":"}{
            if ($(field) != val) {
                print_found=1
                print
            }
        } END {
            if (!print_found) {
                print "\033[31mWarning:\033[0m\nNo data found"
            }
        }' "$tablename" > "$tablename.tmp" && mv "$tablename.tmp" "$tablename"
        echo -e "All rows with this value are deleted \e[32msuccessfully\e[0m."
        echo ""
        return 0
    else
        return 1
    fi
}


# Create table function
function create_table() {
    local tablename=$1
    local column_names=$2
    local types=$3
    local constraints=$4
    local dbname=$5

    if file_exists "$database_path/$dbname/$tablename"; then
        echo -e "\e[31mWarning:\e[0m Table '$tablename' already exists."
        return 1
    fi

    # Create the table file
    touch "$tablename"
    touch "$tablename-metadata.txt"

    # Add the columns to the table
    for ((i = 0; i < ${#column_names[@]}; i++)); do
        echo "  ${column_names[$i]}:${types[$i]}:${constraints[$i]}" >>"$tablename-metadata.txt"
    done

    echo -e "Table '$tablename' created s\e[32msuccessfully\e[0m."

}

# Function to check if a column exists in the header
check_column_existence() {
    local column=$1
    local tablename=$2

    # Use awk to search for the column name in the header
    if awk -F: -v col="$column" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) exit 0} {exit 1}' "$tablename"; then
        echo -e "\e[36mColumn '$column' exists\e[0m "
    else
        echo -e "\e[36mColumn '$column' doesn't exist in the table '$tablename'\e[0m "
    fi
}

# Function to check if a column value exists in the file
check_column_value_existence() {
    local column_value=$1
    local tablename=$2
    local column=$3

    # Use awk to search for the value in the specified column
    if awk -F: -v col="$column" -v val="$column_value" '$col == val { found=1; exit } END { exit !found }' "$tablename"; then
        echo -e "\e[36mValue '$column_value' exists in column '$column'\e[0m "
    else
        echo -e "\e[36mValue '$column_value' does not exist in column '$column'\e[0m "
    fi
}

# ------------------------- create_table function -------------------------#
function create_table() {
    local tablename=$1
    local dbname=$2
    local -n column_names=$3 2>>/dev/null
    local -n types=$4 2>>/dev/null
    local -n constraints=$5 2>>/dev/null

    if file_exists "$database_path/$dbname/$tablename"; then
        echo "Table '$tablename' already exists."
        return 1
    fi

    # Create the table file
    touch "$tablename"
    touch "$tablename-metadata.txt"

    # Add the columns to the table
    for ((i = 0; i < ${#column_names[@]}; i++)); do
        printf "%s" "${column_names[$i]}" >>"$tablename-metadata.txt"
        if ((i < ${#column_names[@]} - 1)); then
            printf ":" >>"$tablename-metadata.txt"
        fi
    done
    echo "" >>"$tablename-metadata.txt"
    for ((i = 0; i < ${#types[@]}; i++)); do
        printf "%s" "${types[$i]}" >>"$tablename-metadata.txt"
        if ((i < ${#column_names[@]} - 1)); then
            printf ":" >>"$tablename-metadata.txt"
        fi
    done
    echo "" >>"$tablename-metadata.txt"
    for ((i = 0; i < ${#constraints[@]}; i++)); do
        printf "%s" "${constraints[$i]}" >>"$tablename-metadata.txt"
        if ((i < ${#column_names[@]} - 1)); then
            printf ":" >>"$tablename-metadata.txt"
        fi
    done

    echo "Table '$tablename' created successfully."

}
