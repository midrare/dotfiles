#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.local/share/wallpapers"

systemctl --user start hyprpaper
until systemctl --user is-active --quiet hyprpaper; do
    sleep 0.1
done

until hyprctl version &>/dev/null; do
    sleep 0.1
done

until hyprctl hyprpaper listloaded &>/dev/null; do
    sleep 0.1
done

until pgrep -x hyprpaper &>/dev/null; do
    sleep 0.1
done

old_walls="$(hyprctl hyprpaper listloaded | rev | cut -d/ -f1 | rev)"
all_walls="$(find "$WALLPAPER_DIR" -type f | rev | cut -d/ -f1 | rev)"
new_wall="$1"


# retry because hyprpaper does not load certain image files for some reason
while true; do
    if [ -z "$new_wall" ]; then
        new_wall="$(printf "$old_walls\n$all_walls" | sort -h | uniq -u | shuf -n 1)"
        if [ -z "$new_wall" ]; then
            new_wall="$(printf "$old_walls" | head -n 1)"
        fi
    fi

    echo "$new_wall"

    hyprctl hyprpaper reload ",$WALLPAPER_DIR/$new_wall" &>/dev/null
    sleep 1

    if hyprctl hyprpaper listloaded | grep -x "$WALLPAPER_DIR/$new_wall" &>/dev/null; then
        break
    fi

    new_wall=""
done
