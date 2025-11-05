#!/usr/bin/env bash

while ! hyprctl version &>/dev/null; do
    sleep 0.05
done

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
CURRENT_WALL="$(hyprctl hyprpaper listloaded)"
WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)

hyprctl hyprpaper reload ",${WALLPAPER}" >/dev/null
