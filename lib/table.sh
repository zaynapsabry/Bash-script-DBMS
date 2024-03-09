#!/bin/bash

database_path="../databases"

#------------------- Function to select all data from the table -------------------------#
select_all_table_data() {
    local tablename=$1
    local dbname=$2
    # Print header
    awk 'BEGIN { FS=":"; color="\033[1;36m"; reset="\033[0m"; }
        NR==1 { 
        gsub(":", "    ");
        printf color $0 reset "\n";
     }' "$tablename"
    # echo "$(head -n 1 ".$tablename-metadata.txt" | tr ':' '\t')"

    # Print data, align columns nicely
    awk 'NR > 1 { gsub(":", "    "); print }' "$tablename"

    echo ""
}

#----------------------- Function to select column data from the table -----------------------#
select_column_data() {
    local tablename=$1
    local field_number=$2
    local dbname=$3
    awk -F: -v col="$field_number" ' NR>1 {print $col}' "$tablename"
    echo "$column"
    echo ""
}

#---------------------- Function to select row data from the table --------------------------#
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

#---------------------- Function to delete all data from the table -----------------------#
delete_all_table_data() {
    local tablename=$1
    local dbname=$2
    truncate --size 0 "$tablename"
    echo -e "All data in "$tablename" deleted\e[32msuccessfully\e[0m."
    echo ""
}

#----------------------- Function to delete column data from the table ------------------#
delete_column_data() {
    local tablename=$1
    local field_number=$2
    local dbname=$3
    local pk_number=$4
    # Use awk to print all columns except the specified one
    if [[ $field_number == $pk_number ]]; then
        echo -e "\e[31mWarning: \e[0mColumn "$pk_number" is the primary key you can't delete it"
        echo ""
    else
        awk -v field="$field_number" 'BEGIN{FS=OFS=":"} {$field=""; $1=$1; print}' "$tablename" >"$tablename.tmp" && mv "$tablename.tmp" "$tablename"

        echo -e "All data in this column deleted \e[32msuccessfully\e[0m."
        echo ""
    fi
}

#------------------------- Function to delete row data from the table ------------------------#
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
        }' "$tablename" >"$tablename.tmp" && mv "$tablename.tmp" "$tablename"
        echo -e "All rows with this value are deleted \e[32msuccessfully\e[0m."
        echo ""
        return 0
    else
        return 1
    fi
}

#-------------------- Function to check if a column exists in the header -------------------- #
check_column_existence() {
    local column=$1
    local tablename=$2

    # Use awk to search for the column name in the header
    if awk -F: -v col="$column" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) exit 0} {exit 1}' "$tablename"; then
        echo -e "\e[36mColumn '$column' exists\e[0m "
    else
        echo -e "\e[36mColumn '$column' doesn't exist in the table '.$tablename-metadata.txt'\e[0m "
    fi
}

#------------------- Function to check if a column value exists in the file ---------------------#
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

    metadata_file=".$tablename-metadata.txt"
    # Create the table file
    touch "$tablename"
    touch $metadata_file

    # Add the columns to the table
    for ((i = 0; i < ${#column_names[@]}; i++)); do
        printf "%s" "${column_names[$i]}" >>$metadata_file
        if ((i < ${#column_names[@]} - 1)); then
            printf ":" >>$metadata_file
        fi
    done
    echo "" >>$metadata_file
    for ((i = 0; i < ${#types[@]}; i++)); do
        printf "%s" "${types[$i]}" >>$metadata_file
        if ((i < ${#column_names[@]} - 1)); then
            printf ":" >>$metadata_file
        fi
    done
    echo "" >>$metadata_file
    for ((i = 0; i < ${#constraints[@]}; i++)); do
        printf "%s" "${constraints[$i]}" >>$metadata_file
        if ((i < ${#column_names[@]} - 1)); then
            printf ":" >>$metadata_file
        fi
    done

    echo -e "Table '$tablename' created \e[32msuccessfully\e[0m."
    echo ""
}

# ------------------------- drop_table function -------------------------#
function drop_table() {
    local tablename=$1
    local dbname=$2

    if file_exists "$tablename"; then
        rm "$tablename"
        rm ".$tablename-metadata.txt"
        echo -e "Table '$tablename' dropped \e[32msuccessfully\e[0m."
    else
        echo -e "\e[31mError\e[0m: Table '$tablename' doesn't exist."
    fi
}

# ------------------------- insert_into_table function -------------------------#
function insert_into_table {
    local tablename=$1
    local -a column_values=($2)

    printf "%s" "${column_values[0]}" >>"$tablename"
    for ((i = 1; i < ${#column_values[@]}; i++)); do
        printf ":%s" "${column_values[$i]}" >>"$tablename"
    done
    echo "" >>"$tablename"
    # echo "$column_values"
    echo -e "Data inserted \e[32msuccessfully\e[0m."
    echo ""

}

#----------------------- Function to update column data in the table ------------------#
update_column_data() {
    local tablename=$1
    local field_number=$2
    local column_value=$3

    # Use awk to update column value with the one entered by user

    awk -v field="$field_number" -v value="$column_value" 'BEGIN{FS=OFS=":"} { $field=value; print }' "$tablename" > "$tablename.tmp" && mv "$tablename.tmp" "$tablename"
    echo -e "All data in this column updated \e[32msuccessfully\e[0m."
    echo ""
}

#----------------------- Function to update row data in the table ------------------#
update_row_data() {
    local tablename=$1
    local where_field_number=$2
    local where_field_value=$3
    local updated_field_number=$4 
    local updated_field_value=$5 

    # Use awk to update row value with the one entered by user
    awk -v where_field="$where_field_number" -v where_value="$where_field_value" -v updated_field="$updated_field_number" -v new_value="$updated_field_value" 'BEGIN{FS=OFS=":"} {
        if ($where_field == where_value) {
            $updated_field = new_value
        }
        print
    }' "$tablename" > "$tablename.tmp" && mv "$tablename.tmp" "$tablename"

    echo -e "Table updated \e[32msuccessfully\e[0m."
    echo ""
}



