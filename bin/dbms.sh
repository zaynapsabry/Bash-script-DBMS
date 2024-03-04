#/bin/bash

source ../lib/menu.sh
source ../lib/createDB.sh
source ../lib/listDB.sh
source ../lib/dropDB.sh

while true; 
do
    #display the main menu
    display_main_menu

    read -p "Enter a number: " choice

    case $choice in
        1) createDB;;
        2) listDB;;
        3) dropDB;;
        4) echo "Connect to a database";;
        5) echo "Exit"
            break ;; 
        *) echo "Invalid choice";;
    esac
done


<<COMMENT
display_main_menu

read -p "Enter a number: " choice

case $choice in 
    1) createDB;;
    2) echo "List existing databases";;
    3) echo "Drop a database";;
    4) echo "Connect to a database";;
    5) echo "Exit";;
    *) echo "Invalid choice";;
esac
COMMENT
