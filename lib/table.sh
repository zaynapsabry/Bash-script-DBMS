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
        }' "$tablename" >"$tablename.tmp" && mv "$tablename.tmp" "$tablename"
        echo -e "All rows with this value are deleted \e[32msuccessfully\e[0m."
        echo ""
        return 0
    else
        return 1
    fi
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

# Function to drop a table
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

function insert_into_table() {
    local tablename=$1
    local dbname=$2
    local -a column_names=($3)
    local metadata_file=".$tablename-metadata.txt"

    local pk_field_number=$(get_primary_key_number "$table")
    local not_null_columns=($(get_not_null_columns "$table"))
    local unique_columns=($(get_unique_columns "$table"))
    # local not_null_columns=$(awk -F: 'NR>=4 && NR<3+$primary_keys {if ($3=="NOT NULL") print $1}' "$metadata_file")
    # local unique_columns=$(awk -F: 'NR>=4 && NR<3+$primary_keys {if ($3=="UNIQUE") print $1}' "$metadata_file")

    local column_values=()
    for ((i = 0; i < ${#column_names[@]}; i++)); do

        read -p "Enter the value for column '${column_names[i]}': " -r column_value

        local column_name=${column_names[i]}

        # check the type of the column value matches the type in the metadata
        local col_type=$(awk -F: -v col="$((i + 1))" '
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

        echo "col type : $col_type"
        if [[ $col_type == "int" ]]; then
            if ! [[ $column_value =~ ^[0-9]+$ ]]; then
                echo -e "\e[31mError:\e[0m The value of the column should be an integer."
                return 1
            fi
        elif [[ $col_type == "string" ]]; then
            if ! [[ $column_value =~ ^[a-zA-Z]+$ ]]; then
                echo -e "\e[31mError:\e[0m The value of the column should be a string."
                return 1
            fi
        fi

        if [[ $column_value == "" ]]; then
            echo -e "\e[31mError:\e[0m The value of the column should not be empty."
            return 1
        fi

        # Check NOT NULL constraint
        # echo not null columns : ${not_null_columns[@]}
        # if [[ " ${not_null_columns[@]} " =~ " $column_name " ]] && [ -z "$column_value" ]; then
        #     echo "Error: $column_name cannot be NULL."
        #     return 1
        # fi

        echo "not null columns : ${not_null_columns[@]}"

        for not_null_column in "${not_null_columns[@]}"; do
            if [[ $((i + 1)) == $not_null_column ]]; then
                if [[ $column_value == "" ]]; then
                    echo "Error: $column_name cannot be NULL."
                    return 1
                fi
            fi
        done

        echo "unique columns : ${unique_columns[@]}"
        # Check UNIQUE constraint
        # if [[ " ${unique_columns[@]} " =~ " $column_name " ]]; then
        #     if grep -q "^$column_value$" "$tablename"; then
        #         echo "Error: $column_name must be unique."
        #         return 1
        #     fi
        # fi

        for unique_column in "${unique_columns[@]}"; do
            if [[ $((i + 1)) == $unique_column ]]; then
                if grep -q "^$column_value$" "$tablename"; then
                    echo "Error: $column_name must be unique."
                    return 1
                else
                    echo "$column_name is unique."
                fi
            fi
        done

        echo "primary keys : $pk_field_number"
        # Check PRIMARY KEY constraint
        if [[ $((i + 1)) == $pk_field_number ]]; then
            if grep -q "^$column_value$" "$tablename"; then
                echo "Error: $column_name must be unique."
                return 1
            else
                echo "$column_name is unique."
            fi
        fi

        column_values[$i]+=$column_value
    done

    # Insert the data into the table
    echo "Inserting data into file: $tablename"
    echo "Column names: ${column_names[@]}"
    echo "Column values: ${column_values[@]}"

    printf "%s" "${column_values[0]}" >>"$tablename"
    for ((i = 1; i < ${#column_values[@]}; i++)); do
        printf ":%s" "${column_values[$i]}" >>"$tablename"
    done
    echo "" >>"$tablename"

    echo -e "Data inserted \e[32msuccessfully\e[0m."
    echo ""
}

#     # Check if the number of columns and values match
#     if [[ ${#column_names[@]} -ne ${#column_values[@]} ]]; then
#         echo -e "\e[31mError:\e[0m The number of columns and values don't match."
#         return 1
#     fi

#     # Check if the primary key is unique
#     local pk_field_number=$(awk -F: '
#         BEGIN { found=0 }
#         NR==3 {
#             split($0, primary_keys)
#             for (i = 1; i <= NF; i++) {
#                 if (primary_keys[i] == "primarykey") {
#                     pk_field_number = i
#                     found = 1
#                     break
#                 }
#             }
#             if (found == 0) {
#                 print "No primary key found"
#             }
#         }
#         END {
#             if (found == 1) {
#                 print pk_field_number
#             }
#         }' "$metadata_file")

#     # local pk_value=${column_values[$pk_field_number - 1]}
#     # if [[ -n $pk_field_number ]]; then
#     #     if awk -F: -v col="$pk_field_number" -v val="$pk_value" 'NR>1 {if ($col == val) {print 1; exit}}' "$tablename"; then
#     #         echo -e "\e[31mError:\e[0m The primary key value '$pk_value' already exists."
#     #         return 1
#     #     fi
#     # fi

#     # Check if the column names exist in the metadata
#     for col in "${column_names[@]}"; do
#         if ! awk -F: -v col="$col" 'NR==1 {for (i=1; i<=NF; i++) if ($i == col) exit 1} {exit 0}' "$metadata_file"; then
#             echo -e "\e[31mError:\e[0m The column '$col' doesn't exist in the table."
#             return 1
#         fi
#     done
# ####validate in utils
#     # Check if the column values match the data types in the metadata
#     for ((i = 0; i < ${#column_names[@]}; i++)); do
#         local col=${column_names[$i]}
#         local col_value=${column_values[$i]}
#         local col_type=$(awk -F: -v col="$col" '
#             BEGIN { found=0 }
#             NR==2 {
#                 split($0, types)
#                 col_type = types[col]
#                 found=1
#             }
#             END {
#                 if (found == 1) {
#                     print col_type
#                 }
#             }' "$metadata_file")

#         if [[ -z $col_type ]]; then
#             echo -e "\e[31mError:\e[0m The column '$col' not found in metadata."
#             return 1
#         fi

#         if [[ $col_type == "int" ]]; then
#             if ! [[ $col_value =~ ^[0-9]+$ ]]; then
#                 echo -e "\e[31mError:\e[0m The value of the column should be an integer."
#                 return 1
#             fi
#         elif [[ $col_type == "string" ]]; then
#             if ! [[ $col_value =~ ^[a-zA-Z]+$ ]]; then
#                 echo -e "\e[31mError:\e[0m The value of the column should be a string."
#                 return 1
#             fi
#         fi
#     done

#     # Check if the column values match the constraints in the metadata
#     for ((i = 0; i < ${#column_names[@]}; i++)); do
#         local col=${column_names[$i]}
#         local col_value=${column_values[$i]}
#         local col_constraint=$(awk -F: -v col="$col" '
#             BEGIN { found=0 }
#             NR==3 {
#                 split($0, constraints)
#                 col_constraint = constraints[col]
#                 found=1
#             }
#             END {
#                 if (found == 1) {
#                     print col_constraint
#                 }
#             }' "$metadata_file")

#         if [[ -n $col_constraint ]]; then
#             if [[ $col_constraint == "unique" ]]; then
#                 if awk -F: -v col="$col" -v val="$col_value" 'NR>1 {if ($col == val) {print 1; exit}}' "$tablename"; then
#                     echo -e "\e[31mError:\e[0m The value of the column '$col' should be unique."
#                     return 1
#                 fi
#             fi
#         fi
#     done
