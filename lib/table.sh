#!/bin/bash

# Function to select all data from the file
select_all_data() {
    local tablename=$1
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

# Function to select column data from the file
select_column_data() {
    local tablename=$1
    local column=$2
    awk -F: -v col="$column" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) col_num=i} NR>1 {print $col_num}' "$tablename"
    echo ""
}

# Function to select row data from the file
select_row_data() {
    local tablename=$1
    local column=$2
    local column_value=$3
    awk -F: -v col="$column" -v val="$column_value" '{ if ($col == val) print }' "$tablename"
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
