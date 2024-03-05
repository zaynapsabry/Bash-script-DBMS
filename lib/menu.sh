#!/bin/bash

source ../lib/database.sh
#display the main menu
function display_main_menu {
    clear
    echo "------------------- Welcome to our DBMS -------------------"
    echo " "
    PS3="Main Menu> "
    select choice in "Create a new database" "List existing databases" "Drop a database" "Connect to a database" "Exit"; do
        case $REPLY in
            1)
                read -p "Enter db name: " name
                createDB "$name"
                if ! createDB; then
                    try-again 
                fi    
            ;;
            2)
                echo "Listing existing databases"
                listDB
            ;;
            3)
                read -p "Enter db name: " name
                dropDB "$name"
                if ! dropDB; then
                    try-again
                fi 
            ;;
            4)
                read -p "Enter db name: " name
                if connect_to_db "$name"; then
                    if ! connect_to_db; then
                        try-again
                    fi
                else 
                    display_table_menu
                fi
            ;;
            5) exit 0 ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

function display_table_menu {
    select choice in "Create a new table" "List existing tables" "Drop a table" "Insert into a table" "Select from a table" "Exit"; do
        case $REPLY in
            1) echo "Create a new table" ;;
            2) echo "List existing tables" ;;
            3) echo "Drop a table" ;;
            4) echo "Insert into a table" ;;
            5) echo "Select from a table" ;;
            6) #exit to the main menu
                
                display_main_menu
                
            ;;
            *) echo "Invalid choice" ;;
        esac
    done
}


function try-agin(){
    read -p "Do you want to choose a different name? (y/n): " choice
        case "$choice" in
        [yY])
            read -p "Enter db name: " name;;
            #function i want to pass name to
        *)
        echo "Exiting..."
            break ;;
        esac
}