#!/bin/bash

source ../lib/menu.sh
source ../lib/database.sh

initiate_databases
while true; do
    display_main_menu
done

