#!/bin/bash

source ../lib/database.sh
source ../lib/table.sh
database_path="../databases"

#continously ask user for input name if he entered wrong name
function try-again() {
    local func="$1"
    local table="$2"
    local column="$3"
    read -p "Do you want to choose a different name? (y/n): " choice
    case "$choice" in
    [yY])
        read -p "Enter name: " name
        $func "$name" "$table" "$column"
        ;;
    *)
        echo "Exiting..."
        return 1
        ;;
    esac
}

#display the main menu
function display_main_menu {
    clear
    initiate_databases
    cd ../$database_path 2>>/dev/null

    # Draw DBMS in ASCII art
    echo -e "\e[35m zz zz zz     ss ss ss     zz        zz    ss ss ss   \e[0m"
    echo -e "\e[35m zz      zz   ss      ss   zz zz  zz zz  ss           \e[0m   "
    echo -e "\e[35m zz       zz  ss ss ss     zz   zz   zz    ss ss ss   \e[0m "
    echo -e "\e[35m zz      zz   ss      ss   zz        zz            ss \e[0m"
    echo -e "\e[35m zz zz zz     ss ss ss     zz        zz    ss ss ss   \e[0m "

    echo " "
    PS3="Main Menu> "
    select choice in "Create a new database" "List existing databases" "Drop a database" "Connect to a database" "Rename DB" "Exit"; do
        case $REPLY in
        1)
            read -p "Enter db name to create: " name
            if ! createDB "$name"; then
                try-again createDB
            fi
            ;;
        2)
            listDB
            ;;
        3)
            if ! directory_empty $database_path; then
                echo -e "\e[36mThese are the databases in the system:\e[0m"
                echo -e "\e[36mChoose what you want to drop:\e[0m"
                databases=($(ls "$database_path"))
                select db in "${databases[@]}"; do
                    if [[ -n $db ]]; then
                        dropDB "$db"

                        display_main_menu
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        read -p "Press (C/c) to continue: " choice
                        case "$choice" in
                        [cC])

                            display_main_menu
                            ;;
                        *)
                            echo "Exit...."
                            exit
                            ;;
                        esac
                    fi
                done
            else
                echo -e "\e[31mWarning:\e[0m There ara no databases in the system"
            fi
            ;;
        4)
            if ! directory_empty $database_path; then
                echo -e "\e[36mThese are the databases in the system:\e[0m"
                echo -e "\e[36mChoose what you want to connect:\e[0m"
                databases=($(ls "$database_path"))
                select db in "${databases[@]}"; do
                    if [[ -n $db ]]; then
                        connect_to_db "$db"
                        display_table_menu "$db"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        read -p "Press (C/c) to continue: " choice
                        case "$choice" in
                        [cC])
                            cd ../$database_path
                            display_main_menu

                            ;;
                        *)
                            echo "Exit...."
                            exit
                            ;;
                        esac
                    fi
                done
            else
                echo -e "\e[31mWarning:\e[0m There ara no databases in the system"
            fi
            ;;
        5)
            if ! directory_empty $database_path; then
                echo -e "\e[36mThese are the databases in the system:\e[0m"
                echo -e "\e[36mChoose what you want to rename:\e[0m"
                databases=($(ls "$database_path"))
                select db in "${databases[@]}"; do
                    if [[ -n $db ]]; then
                        valid=1
                        while [ $valid -eq 1 ]; do
                            read -p "Enter new name: " new_name
                            if renameDB "$db" "$new_name"; then
                                valid=0
                            fi
                        done
                        display_main_menu
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        read -p "Press (C/c) to continue: " choice
                        case "$choice" in
                        [cC])
                            display_main_menu
                            ;;
                        *)
                            echo "Exit...."
                            exit
                            ;;
                        esac
                    fi
                done
            else
                echo -e "\e[31mWarning:\e[0m There ara no databases in the system"
            fi
            ;;
        6) exit 0 ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

function display_table_menu {
    local dbname=$1
    select choice in "Create a new table" "List existing tables" "Drop a table" "Insert into a table" "Select from a table" "Delete from a table" "Update a table" "Exit"; do
        case $REPLY in
        1) # Creating a table
            display_create_table_menu "$dbname"
            display_table_menu "$dbname"
            ;;
        2) # Listing table contents
            if directory_empty "$PWD"; then
                echo -e "\e[36mThere is no tables in "$dbname" database\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"

                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                echo -e "\e[36mThese are the tables in "$dbname" database\e[0m"
                ls
                echo ""
                PS3="$dbname> "
                display_table_menu "$dbname"
            fi

            ;;
        3) # Dropping a table
            echo -e "\e[36mChoose a table to drop:\e[0m"
            tables=($(ls "../$dbname"))
            select table in "${tables[@]}"; do
                if [[ -n $table ]]; then
                    drop_table "$table" "$dbname"
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                else
                    echo -e "\e[31mWarning:\e[0m invalid choice"
                    read -p "Press (C/c) to continue: " choice
                    case "$choice" in
                    [cC])
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                        ;;
                    *)
                        echo "Exit...."
                        exit
                        ;;
                    esac
                fi
            done
            ;;
        4) # Insert data into a table
            echo -e "\e[36mChoose a table to insert into:\e[0m"
            tables=($(ls "../$dbname"))
            select table in "${tables[@]}"; do
                if [[ -n $table ]]; then
                    fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))
                    pk_field_number=$(get_primary_key_number "$table")

                    echo -e "\e[36mThese are the fields in table $table:\e[0m"
                    echo "${fields[@]}"
                    echo -e "The primary key field is: ${fields[$pk_field_number - 1]}"

                    col_values=$(enter_row_data "$table" "${fields[*]}")

                    last_index=$((${#col_values[@]} - 1))
                    last_element="${col_values[last_index]}"

                    insert_into_table "$table" "${last_element[*]}"
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                else
                    echo -e "\e[31mWarning:\e[0m invalid choice"
                    read -p "Press (C/c) to continue: " choice
                    case "$choice" in
                    [cC])
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                        ;;
                    *)
                        echo "Exit...."
                        exit
                        ;;
                    esac
                fi
            done

            ;;
        5) # Select from a table
            echo -e "\e[36mChoose a table to select from:\e[0m"
            tables=($(ls "../$dbname"))
            select table in "${tables[@]}"; do
                if [[ -n $table ]]; then
                    display_select_from_table_menu "$table" "$dbname"
                else
                    echo -e "\e[31mWarning:\e[0m invalid choice"
                    read -p "Press (C/c) to continue: " choice
                    case "$choice" in
                    [cC])
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                        ;;
                    *)
                        echo "Exit...."
                        exit
                        ;;
                    esac
                fi
            done
            ;;
        6) # Delete from a table
            echo -e "\e[36mChoose a table to delete from:\e[0m"
            tables=($(ls "../$dbname"))
            select table in "${tables[@]}"; do
                if [[ -n $table ]]; then
                    display_delete_from_table_menu "$table" "$dbname"
                else
                    echo -e "\e[31mWarning:\e[0m invalid choice"
                    read -p "Press (C/c) to continue: " choice
                    case "$choice" in
                    [cC])
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                        ;;
                    *)
                        echo "Exit...."
                        exit
                        ;;
                    esac
                fi
            done
            ;;
        7) # Update a table
            echo -e "\e[36mChoose a table to update:\e[0m"
            tables=($(ls "../$dbname"))
            select table in "${tables[@]}"; do
                if [[ -n $table ]]; then
                    display_update_table_menu "$table" "$dbname"
                else
                    echo -e "\e[31mWarning:\e[0m invalid choice"
                    read -p "Press (C/c) to continue: " choice
                    case "$choice" in
                    [cC])
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                        ;;
                    *)
                        echo "Exit...."
                        exit
                        ;;
                    esac
                fi
            done
            ;;
        8)
            display_main_menu

            ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}
#------------------------------- insert_into_table input from user -------------------------------#
function enter_row_data {
    local tablename=$1
    local -a column_names=($2)
    # local field_numbers=$3

    local column_values=()
    for ((i = 0; i < ${#column_names[@]}; i++)); do

        local column_name=${column_names[i]}

        valid=0
        while [ $valid -eq 0 ]; do
            read -p "Enter the value for column '${column_names[i]}': " column_value
            if validate_col_type_value_input "$tablename" "$column_value" "$(($i + 1))"; then
                if validate_col_constraint_value_input_match "$tablename" "$column_value" "$(($i + 1))"; then
                    valid=1
                fi
            fi
            # echo "$(($i+1))"
        done

        column_values[$i]=$column_value
    done

    echo "${column_values[@]}"
}

#------------------------------- display_select_from_table_menu function -------------------------------#

function display_select_from_table_menu {
    local table=$1
    local dbname=$2
    PS3="Select from table $table> "
    select choice in "Select all" "Select column" "Select row" "Exit"; do
        case $REPLY in
        1)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                select_all_table_data "$table" "$dbname"
                PS3="$dbname> "
                display_table_menu "$dbname"
            fi
            ;;
        2)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                echo -e "\e[36mThese are the fileds in table "$table":\e[0m"
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))
                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        echo -e "\e[36mThese are the data in $field\e[0m"
                        select_column_data "$table" "$REPLY" "$dbname"
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        3)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                echo -e "\e[36mThese are the fileds in table "$table":\e[0m"
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))
                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        read -p "Please enter the column value to get it's rows: " column_value
                        #validation on column value
                        if ! select_row_data "$table" "$REPLY" "$column_value" "$dbname"; then
                            echo -e "\e[31mWarning:\e[0m No data found"
                            display_select_from_table_menu "$table" "$dbname"
                        fi
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_from_table_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        4) display_table_menu "$dbname" ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

#------------------------------- display_delete_from_table_menu function -------------------------------#

function display_delete_from_table_menu {
    local table=$1
    local dbname=$2
    PS3="Delete from table $table> "
    select choice in "Delete all" "Delete Column" "Delete row" "Exit"; do
        case $REPLY in
        1)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                delete_all_table_data "$table" "$dbname"
                PS3="$dbname> "
                display_table_menu "$dbname"
            fi
            ;;
        2)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                echo -e "\e[36mThese are the fileds in table "$table":\e[0m"
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))

                pk_field_number=$(get_primary_key_number "$table")
                # echo "$pk_field_number"

                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        delete_column_data "$table" "$REPLY" "$dbname" "$pk_field_number"
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        3)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                echo -e "\e[36mThese are the fileds in table "$table":\e[0m"
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))
                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        read -p "Please enter the column value to get it's rows: " column_value
                        #validation on column value
                        if ! delete_row_data "$table" "$REPLY" "$column_value" "$dbname"; then
                            echo -e "\e[31mWarning:\e[0m No data found"
                            display_select_from_table_menu "$table" "$dbname"
                        fi
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_from_table_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        4) display_table_menu "$dbname" ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

#------------------------------- display_update_table_menu function -------------------------------#

function display_update_table_menu {
    local table=$1
    local dbname=$2
    PS3="Update table $table> "
    select choice in "Update Column" "Update row" "Exit"; do
        case $REPLY in
        1)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                echo -e "\e[36mThese are the fileds in table "$table":\e[0m"
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))

                pk_field_number=$(get_primary_key_number "$table")

                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        pk_valid=0
                        while [ $pk_valid -eq 0 ]; do
                            if (($REPLY == $pk_field_number)); then
                                echo -e "\e[31mWarning:\e[0m Column "$field" is the primary key and can't be updated"
                                echo ""
                                display_update_table_menu "$table" "$dbname"
                            fi

                            local unique_fields=$(get_unique_columns "$table")
                            if [[ "${unique_fields[@]}" =~ "$REPLY" ]]; then
                                echo -e "\e[31mWarning:\e[0m Column "$field" has a unique constrains and can't be updated"
                                echo ""
                                display_update_table_menu "$table" "$dbname"
                            fi

                            pk_valid=1
                        done

                        valid=0
                        while [ $valid -eq 0 ]; do
                            read -p "Please enter the value you want to set this field with: " column_value
                            if validate_col_type_value_input "$table" "$column_value" "$REPLY"; then
                                valid=1
                            fi
                        done

                        update_column_data "$table" "$REPLY" "$column_value"
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        2)
            if ! file_empty "$table"; then
                echo -e "\e[36mThere is no data in table "$table"\e[0m"
                read -p "Press (C/c) to continue: " choice
                case "$choice" in
                [cC])
                    PS3="$dbname> "
                    display_table_menu "$dbname"
                    ;;
                *)
                    echo "Exit...."
                    exit
                    ;;
                esac
            else
                local where_field
                local where_field_value
                echo -e "\e[36mThese are the fileds in table "$table":\e[0m"
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' ".$table-metadata.txt"))

                echo -e "\e[36mChoose the field of the where clause:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        valid=0
                        while [ $valid -eq 0 ]; do
                            read -p "Please enter the value of $field: " column_value
                            if validate_col_type_value_input "$table" "$column_value" "$REPLY"; then
                                local field_values=$(get_field_values "$table" "$REPLY")
                                if [[ "${field_values[@]}" == *"$column_value"* ]]; then
                                    valid=1
                                else
                                    # read -p $'\e[31mWarning:\e[0m Column '"$field"' doesn\'t have this value\n\nPlease enter the value of '"$field"': " column_value

                                    echo -e "\e[31mWarning:\e[0m Column $field doesn't have this value"
                                    echo ""
                                    read -p "Please enter the value of $field: " column_value
                                fi
                            fi
                        done

                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_from_table_menu "$table" "$dbname"
                    fi
                    where_field="$REPLY"
                    where_field_value="$column_value"
                    break
                done

                echo -e "\e[36mChoose the field you want to update:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        valid=0
                        while [ $valid -eq 0 ]; do
                            read -p "Please enter the value to update with: " column_value
                            if validate_col_type_value_input "$table" "$column_value" "$REPLY"; then
                                if validate_col_constraint_value_input_match "$table" "$column_value" "$REPLY"; then
                                    valid=1
                                fi
                            fi
                        done

                        update_row_data "$table" "$where_field" "$where_field_value" "$REPLY" "$column_value"
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_from_table_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        3) display_table_menu "$dbname" ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

#------------------------------- display_create_table_menu function -------------------------------#
function display_create_table_menu {
    local dbname=$1
    local column_names=()
    local types=()
    local constraints=()
    # local primary_key_selected=false
    primary_key_selected=0
    
    valid_name=1
    while [ $valid_name -eq 1 ]; do
        read -p "Enter table name to create: " name
        if validate_name "$name"; then
            if file_exists "$name"; then
                echo -e "\e[31mError\e[0m: Table '$name' already exists."
                echo ""
                return 1
            fi
            valid_name=0
        fi
    done

    valid_num=1
    while [ $valid_num -eq 1 ]; do
        read -p "Enter number of columns: " num_col
        if validate_num "$num_col"; then
            valid_num=0
        fi
    done

    for ((i = 0; i < num_col; i++)); do

        valid_name=1
        while [ $valid_name -eq 1 ]; do
            read -p "Enter column name: " col_name

            if [[ "${column_names[@]}" =~ "$col_name" ]]; then
                echo -e "\e[31mError\e[0m: Column '$col_name' already exists."
                echo ""
                valid_name=1
            elif ! validate_name "$col_name"; then
                valid_name=1
            else
                valid_name=0
            fi
        done

        column_names+=("$col_name")

        valid_choice=1
        while [ $valid_choice -eq 1 ]; do

            if display_select_type_menu "${types[@]}"; then
                valid_choice=0
            fi
        done
        valid_choice=1

       
        while [ "$valid_choice" -eq 1 ]; do
            if display_select_constrain_menu "${constraints[@]}"; then
             
                valid_choice=0

            fi
        done

    done
    if [[ ! "${constraints[@]}" =~ "primarykey" ]]; then
        echo -e "\e[31mWarning:\e[0m Primary key is required"
        echo ""
        display_create_table_menu "$dbname"

    else
        create_table "$name" "$dbname" "${column_names[@]}" "${types[@]}" "${constraints[@]}"
    fi
}

#------------------------------- display_select_type_menu function -------------------------------#

function display_select_type_menu {
    local -n types=$1 2>>/dev/null
    select type in "int" "string"; do
        case $REPLY in
        1)
            types+=("int")
            return 0
            ;;
        2)
            types+=("string")
            return 0
            ;;
        *)
            echo "Invalid choice"
            return 1
            ;;
        esac
        break
    done
}

#------------------------------- display_select_constrains_menu function -------------------------------#

function display_select_constrain_menu {
    local -n constraints=$1 2>/dev/null # Reference to the array passed as argument
   
    if [[ $primary_key_selected -eq 0 ]]; then
        select constrain in "primary key" "unique" "not null" "none"; do
            case $REPLY in
            1)
                constraints+=("primarykey")
                primary_key_selected=1
                return 0
                ;;
            2)
                constraints+=("unique")
                return 0
                ;;
            3)
                constraints+=("notnull")
                return 0
                ;;
            4)
                constraints+=("none")
                return 0
                ;;
            *)
                echo "Invalid choice"
                return 1
                ;;
            esac
        done
    else
        # If primary key already selected, show menu without the option for primary key
        select constrain in "unique" "not null" "none"; do
            case $REPLY in
            1)
                constraints+=("unique")
                return 0
                ;;
            2)
                constraints+=("notnull")
                return 0
                ;;
            3)
                constraints+=("none")
                return 0
                ;;
            *)
                echo "Invalid choice"
                return 1
                ;;
            esac
        done
    fi
}
