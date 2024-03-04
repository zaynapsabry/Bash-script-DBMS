#! /bin/bash
source ../lib/util.sh
source ../lib/menu.sh

function listDB(){
if [ -d "../databases" ] && [ "$(ls -A ../databases)" ];
then
    echo "These are the databases in the system:"  
    for db in $(ls ../databases)
    do
        echo "$db"
    done
else
    echo "There are no databases in the system :(" 
fi
}

