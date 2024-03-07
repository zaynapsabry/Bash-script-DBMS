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
    cd ../$database_path
    echo -e "\e[36m--------------------- Welcome to ZSH DBMS --------------------\e[0m"
    echo " "
    PS3="Main Menu> "
    select choice in "Create a new database" "List existing databases" "Drop a database" "Connect to a database" "Exit"; do
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
            ;;
        4)
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
            ;;
        5) exit 0 ;;
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
        3) echo "Drop a table" ;;
        4) echo "Insert into a table" ;;
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
        7) echo "Update a table" ;;
        8)
            display_main_menu

            ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

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
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' "$table"))
                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        echo -e "\e[36mThese are the data in $field\e[0m"
                        select_column_data "$table" "$field" "$dbname"
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
                fields=($(awk -F: 'NR==1 { gsub(":", "\t"); print }' "$table"))
                echo -e "\e[36mChoose field:\e[0m"
                select field in "${fields[@]}"; do
                    if [[ -n $field ]]; then
                        read -p "Please select the column value to get it's rows: " column_value
                        #validation on column value
                        select_row_data "$table" "$column" "$column_value" "$dbname"
                        PS3="$dbname> "
                        display_table_menu "$dbname"
                    else
                        echo -e "\e[31mWarning:\e[0m invalid choice"
                        display_select_menu "$table" "$dbname"
                    fi
                done
            fi
            ;;
        4) display_table_menu "$dbname" ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

function display_delete_from_table_menu {
    local table=$1
    local dbname=$2
    PS3="Delete from table $table> "
    select choice in "Delete all" "Delete row" "Exit"; do
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
            echo "Delete rows"

            ;;
        3) display_table_menu "$dbname" ;;
        *) echo -e "\e[31mWarning:\e[0m invalid choice" ;;
        esac
    done
}

function display_create_table_menu {
    local dbname=$1
    local column_names=""
    local types=""
    local constraints=""

    read -p "Enter table name to create: " name
    while ! validate_name "$name"; do
        read -p "Enter table name to create: " name
    done

    read -p "Enter number of columns " num_col
    while ! validate_num "$num_col"; do
        read -p "Enter number of columns " num_col
    done

    for ((i = 1; i <= num_col; i++)); do
        read -p "Enter column $i name: " col_name
        if ! validate_name "$col_name"; then
            read -p "Enter column $i name: " col_name
        fi
        column_names+="$col_name:"
        select type in "int" "string"; do
            case $REPLY in
            1) types+="int:" ;;
            2) types+="string:" ;;
            *) echo "Invalid choice" ;;
            esac
            break
        done
        select constrain in "primary key" "unique" "not null"; do
            case $REPLY in
            1) constraints+="primary key:" ;;
            2) constraints+="unique:" ;;
            3) constraints+="not null:" ;;
            *) echo "Invalid choice" ;;
            esac
            break
        done
    done
    create_table "$name" "$column_names" "$types" "$constraints" "$dbname"
}

function display_create_table_menu {
    local dbname=$1
    local column_names=()
    local types=()
    local constraints=()

    valid_name=1
    while [ $valid_name -eq 1 ]; do
        read -p "Enter table name to create: " name
        if validate_name "$name"; then
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
            if validate_name "$col_name"; then
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
        while [ $valid_choice -eq 1 ]; do

            if display_select_constrain_menu "${constraints[@]}"; then
                valid_choice=0
            fi

        done

    done
    create_table "$name" "$dbname" "${column_names[@]}" "${types[@]}" "${constraints[@]}"
}

function display_select_type_menu {
    local -n types=$1 2>> /dev/null
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

function display_select_constrain_menu {
    local -n constraints=$1 2> /dev/null
    select constrain in "primary key" "unique" "not null" "none"; do
        case $REPLY in
        1)
            constraints+=("primarykey")
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
        break
    done
}
