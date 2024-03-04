#! /bin/bash
source ../lib/util.sh
source ../lib/menu.sh

function dropDB(){
local dbname

    while true; 
    do
        read -p "Enter the name of the database you want to drop: " dbname
        if validate_name "$dbname";
        then
            if directory_exists "$dbname";     # There is no database with the same name as user entered
            then
		echo -e "\e[31mError\e[0m: Database '$dbname' doesn't exist."
                read -p "Do you want to choose a different name? (y/n): " choice
                case "$choice" in
                [yY])
                    continue ;;
                *)
                    echo "Exiting..."
                    break ;;
                esac
            else    # There is a database with the same name as user entered   
	        rm -r "../databases/$dbname"
                echo -e "Database '$dbname' dropped \e[32msuccessfully\e[0m."
            fi
            break
        else
            echo "Please enter a valid name."
        fi
    done
}

