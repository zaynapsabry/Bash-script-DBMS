#!/bin/bash

source ../lib/database.sh
source ../lib/table.sh
database_path="../databases"

#continously ask user for input name if he entered wrong name
function try-again(){
    local func="$1"
    local table="$2"
    local column="$3"
    read -p "Do you want to choose a different name? (y/n): " choice
        case "$choice" in
        [yY])
            read -p "Enter name: " name
            $func "$name" "$table" "$column";;
        *)
        echo "Exiting..."
            return 1;;
        esac
}

#display the main menu
function display_main_menu {
    local dbs_drop=""
    local dbs_connect=""
    clear
    echo -e "\e[36m--------------------- Welcome to ZSH DBMS --------------------\e[0m"
    echo " "
    PS3="Main Menu> "
    select choice in "Create a new database" "List existing databases" "Drop a database" "Connect to a database" "Exit"; do
        case $REPLY in
            1)
                read -p "Enter db name to create: " name
                if ! createDB "$name" ; then
                    try-again createDB
                fi    
            ;;
            2)
                echo "Listing existing databases"
                listDB
            ;;
            3)
                echo -e "\e[36mThese are the databases in the system:\e[0m"
                for db in $(ls "$database_path")
                do
                    dbs_drop+="$(basename "$db")  " 
                done
                echo "$dbs_drop"

                read -p "Enter db name to drop: " name
                if ! dropDB "$name"; then
                    try-again "dropDB"
                fi 
            ;;
            4)
                echo -e "\e[36mThese are the databases in the system:\e[0m"
                for db in $(ls "$database_path")
                do
                    dbs_connect+="$(basename "$db")  " 
                done
                echo "$dbs_connect"

                read -p "Enter db name to connect: " name
                if ! connect_to_db "$name"; then
                    try-again "connect_to_db"
                else 
                    display_table_menu "$name"
                fi
            ;;
            5) exit 0 ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

function display_table_menu {
    local dbname=$1
    local tables=""
    select choice in "Create a new table" "List existing tables" "Drop a table" "Insert into a table" "Select from a table" "Exit"; do
        case $REPLY in
            1) echo "Create a new table" ;;
            2) echo "List existing tables" ;;
            3) echo "Drop a table" ;;
            4) echo "Insert into a table" ;;
            5) 
                # echo -e "\e[36mThese are the tables in $dbname:\e[0m"
                # for table in $(ls "../$dbname")
                # do
                #     tables+="$(basename "$table")  " 
                # done
                # echo "$tables"

                read -p "Enter table name you want to select from: " name
                if ! file_exists "$name"; then
                    echo -e "\e[31mWarning\e[0mThere is no table with this name"
                    display_table_menu
                else  
                    display_select_menu "$name" "$dbname"
                fi;;
            6) #exit to the main menu
                
                display_main_menu
                
            ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

function display_select_menu {
    local table=$1
    local dbname=$2
    PS3="Select from $2 Menu> "
    select choice in "Select all" "Seclect column" "Select row" "Exit"; do
        case $REPLY in
            1)
                select_all_data "$table" 
                display_select_menu "$table" "$dbname"  
            ;;
            2)
                echo -e "\e[36mThese are the fileds in this table:\e[0m"
                awk 'NR==1 { gsub(":", "\t"); print }' "$table"

                read -p "Enter column name you want to select: " column
                if ! check_column_existence "$column" "$table"; then
                    try-again "check_column_existence"
                else
                    select_column_data "$table" "$column"
                    display_select_menu "$table" "$dbname"    
                fi                             
            ;;
            3)
                echo -e "\e[36mThese are the fileds in this table:\e[0m"
                awk 'NR==1 { gsub(":", "\t"); print }' "$table"

                read -p "Enter column name you want to select: " column
                if ! check_column_existence "$column" "$table"; then
                    try-again "check_column_existence" "$table"
                else
                    read -p "Enter value you want to select: " column_value
                    select_row_data "$table" "$column" "$column_value"
                    display_select_menu "$table" "$dbname" 
                    # if ! check_column_value_existence "$column_value" "$table" "$column" ; then
                    #     try-again "check_column_value_existence" "$table" "$column"
                    # else
                    #     select_row_data "$table" "$column" "$column_value"
                    #     display_select_menu "$table" "$dbname"  
                    # fi  
                fi 
            ;;
            4) display_table_menu;;
            *) echo "Invalid choice" ;;
        esac
    done
}
