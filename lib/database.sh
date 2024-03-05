#!/bin/bash
source ../lib/util.sh

database_path="../databases"

#--------------- function to create a database ----------------#

function createDB(){
    local dbname=$1
    if ! validate_name "$dbname" ; then
        return 1
    fi
    # There is no database with the same name as user entered
    if ! directory_exists "$database_path/$dbname";
    then
        # Check if the 'databases' directory exists, if not, create it
        mkdir -p "$database_path/$dbname"
        echo -e "Database '$dbname' created \e[32msuccessfully\e[0m."
        return 0
        # There is a database with the same name as user entered
    else
        echo -e "\e[31mWarning\e[0m: Database '$dbname' already exists."
        return 1
    fi
}

#--------------- function to list all database ----------------#

function listDB(){
    local databases = ""
    if [ -d "$database_path" ] && [ "$(ls -A "$database_path")" ];
    then
        echo "These are the databases in the system:"
        for db in $(ls "$database_path")
        do
            databases+="$(basename "$db") " 
        done
        echo "$databases"
    else
        echo "There are no databases in the system :("
    fi
}

#--------------- function to drop all database ----------------#


function dropDB(){
    local dbname=$1
    if  ! validate_name "$dbname" ; then
        return 1
    fi
    # There is no database with the same name as user entered
    if ! directory_exists "$database_path/$dbname";
    then
        echo -e "\e[31mError\e[0m: Database '$dbname' doesn't exist."
        return 1
        # There is a database with the same name as user entered
    else
        rm -r "$database_path/$dbname"
        echo -e "Database '$dbname' dropped \e[32msuccessfully\e[0m."
        return 0
    fi
}

#--------------- function to connect to a database ----------------#

function connect_to_db {
    local db_name=$1
    if ! validate_name "$db_name"; then
        return 1
    fi
    if ! directory_exists $database_path/$db_name; then
        echo -e "\e[31mWarning\e[0m: Database does not exist"
        return 1
    else
        echo -e "Connecting to \e[33m$db_name\e[0m"
        
        cd $database_path/$db_name
        #echo $PWD #print working directory for testing
        PS3="$db_name> " #change the prompt to the db name
        return 0
    fi
}