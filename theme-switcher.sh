#!/bin/bash

# Create a temp dir
TMP_DIR=$(mktemp -d -t theme-switcher.XXXXXX)
trap "rm -rf \"$TMP_DIR\"" EXIT

menu() {
    clear
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
            curl -L -s -o "$TMP_DIR/theme.zip" https://github.com/DawidDe/Arch-Themes/raw/refs/heads/main/rias-gremory/theme.zip
            unzip "$TMP_DIR/theme.zip" -d "$TMP_DIR"
            rm -r hypr wybar assets
            mv $TMP_DIR/hypr ~/.config/hypr
            mv $TMP_DIR/waybar ~/.config/waybar
            mv $TMP_DIR/assets ~/.config/assets
            ;;
        2)
            clear
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done