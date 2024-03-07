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
     }' "$database_path/$dbname/$tablename"
    # echo "$(head -n 1 "$tablename" | tr ':' '\t')"

    # Print data, align columns nicely
    awk 'NR > 1 { gsub(":", "    "); print }' "$database_path/$dbname/$tablename"

    echo ""
}

# Function to select column data from the table
select_column_data() {
    local tablename=$1
    local column=$2
    local dbname=$3
    awk -F: -v col="$column" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) col_num=i} NR>1 {print $col_num}' "$database_path/$dbname/$tablename"
    echo ""
}

# Function to select row data from the table
select_row_data() {
    local tablename=$1
    local column=$2
    local column_value=$3
    local dbname=$4

    head -n 1 "$tablename" | tr ':' "  "
    # Use awk to iterate over each row in the file
    awk -F: -v col="$column" -v val="$column_value" 'BEGIN{OFS="\t";FS=":"}{
        if (NR == 1) {
            for (i = 1; i <= NF; i++) {
                if ($i == col) {
                    col_index = i
                    break
                }
            }
        } else {
            if ($(col_index) == val) {
                print
            }
        }
    }' "$tablename"  | column -s: -t
    echo ""
}

# Function to delete all data from the table
delete_all_table_data() {
    local tablename=$1
    local dbname=$2
    truncate --size 0 "$database_path/$dbname/$tablename"
    echo -e "All data in "$tablename" deleted\e[32msuccessfully\e[0m."
    echo ""
}


# Create table function
function create_table() {
    local tablename=$1
    local column_names=$2
    local types=$3
    local constraints=$4
    local dbname=$5

    if  file_exists "$database_path/$dbname/$tablename"; then
        echo -e "\e[31mWarning:\e[0m Table '$tablename' already exists."
        return 1
    fi

    # Create the table file
    touch "$tablename"
    touch "$tablename-metadata.txt"

    # Add the columns to the table
    for ((i=0; i<${#column_names[@]}; i++)); do
        echo "  ${column_names[$i]}:${types[$i]}:${constraints[$i]}" >> "$tablename-metadata.txt"
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
    local -n column_names=$3 2>> /dev/null
    local -n types=$4 2>> /dev/null
    local -n constraints=$5  2>> /dev/null

    if file_exists "$database_path/$dbname/$tablename"; then
        echo "Table '$tablename' already exists."
        return 1
    fi

    # Create the table file
    touch "$tablename"
    touch "$tablename-metadata.txt"

    # Add the columns to the table
    for ((i = 0; i < ${#column_names[@]}; i++)); do
        printf "%s:%s:%s\n" "${column_names[$i]}" "${types[$i]}" "${constraints[$i]}" >>"$tablename-metadata.txt"
    done

    echo "Table '$tablename' created successfully."

}

