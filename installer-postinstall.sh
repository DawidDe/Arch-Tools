#!/bin/bash

bloatapps=(
    gnome-contacts
    gnome-weather
    gnome-clocks
    gnome-maps
    gnome-music
    gnome-calendar
    gnome-characters
    gnome-tour
    gnome-font-viewer
    gnome-logs
    gnome-disk-utility
    gnome-system-monitor
    loupe
    malcontent
    papers
    showtime
    simple-scan
    snapshot
    baobab
    decibels
    epiphany
)

essentialapps=(
    git
    nano
    chromium
    discord
    steam
    code
    spotify-launcher
    bitwarden
)

sudo pacman -Rns "${bloatapps[@]}"

sudo pacman -Syu "${essentialapps[@]}"