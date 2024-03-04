#/bin/bash

source ../lib/menu.sh

#display the main menu
display_main_menu

read -p "Enter a number: " choice

case $choice in 
    1) echo "Create a new database";;
    2) echo "List existing databases";;
    3) echo "Drop a database";;
    4) echo "Connect to a database";;
    5) echo "Exit";;
    *) echo "Invalid choice";;
esac

