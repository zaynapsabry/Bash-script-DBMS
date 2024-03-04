#! /bin/bash
source ../lib/util.sh
source ../lib/menu.sh

#function to create a database
function createDB(){
    local dbname

    while true; 
    do
        read -p "Enter the name of the new database: " dbname
        if validate_name "$dbname"; 
        then
            if ! directory_exists "$dbname";    # There is no database with the same name as user entered
            then
                # Check if the 'databases' directory exists, if not, create it
                if [ ! -d "../databases" ];
                then
                     mkdir "../databases"
                fi

                mkdir "../databases/$dbname"
                echo -e "Database '$dbname' created \e[32msuccessfully\e[0m."


            else       # There is a database with the same name as user entered
		echo -e "\e[31mError\e[0m: Database '$dbname' already exists."

                read -p "Do you want to choose a different name? (y/n): " choice
                case "$choice" in
                [yY])
                    continue ;;
                *)
                    echo "Exiting..."
                    break ;;
                esac

            fi
            break
        else
            echo "Please enter a valid name."
        fi
    done
}
