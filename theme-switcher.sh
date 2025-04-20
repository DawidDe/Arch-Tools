#!/bin/bash

# Create a temp dir
TMP_DIR=$(mktemp -d -t theme-switcher.XXXXXX)
trap "rm -rf \"$TMP_DIR\"" EXIT

menu() {
    echo "|============================|"
    echo "|           THEMES           |"
    echo "|============================|"
    echo "|1) Rias Gremory             |"
    echo "|2) Exit                     |"
    echo "|============================|"
}

while true; do
    menu
    read -p "Choose an option: " choice
    case $choice in
        1)
            echo "You chose Rias Gremory!"
            # Add your theme change logic here
            read -p "Press Enter to return to the menu..."
            ;;
        2)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done