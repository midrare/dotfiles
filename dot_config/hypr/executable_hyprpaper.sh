#!/usr/bin/env bash

calc_greatest_common_denominator() {
  a=$1
  b=$2
  while [ "$b" -ne 0 ]; do
    t=$b
    b=$((a % b))
    a=$t
  done
  echo "$a"
}

get_monitor_resolution() {
  # hyprland
  if command -v hyprctl >/dev/null 2>&1; then
    hyprland_monitors="$(hyprctl monitors -j 2>/dev/null)"
    if [ -n "${hyprland_monitors}" ]; then
      hyprland_monitor_x="${hyprland_monitors##*\"width\": }"
      hyprland_monitor_x="${hyprland_monitor_x%%,*}"

      hyprland_monitor_y="${hyprland_monitors##*\"height\": }"
      hyprland_monitor_y="${hyprland_monitor_y%%,*}"

      echo "${hyprland_monitor_x}x${hyprland_monitor_y}"
      return 0
    fi
  fi

  echo "0x0"
  return 1
}

res=$(get_monitor_resolution) || {
  echo "Unable to detect monitor resolution" >&2
  exit 1
}

gcd=$(calc_greatest_common_denominator "${res%x*}" "${res#*x}")
ratio="$((${res%x*} / $gcd))x$((${res#*x} / $gcd))"


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

old_walls="$(hyprctl hyprpaper listloaded | sed -e "s/@[0-9]+x[0-9]+//" | rev | cut -d/ -f1 | rev)"
all_walls="$(find "$WALLPAPER_DIR" -type f | grep -v "@" | rev | cut -d/ -f1 | rev)"
new_wall="$1"

# retry because hyprpaper does not load certain image files for some reason
while true; do
  if [ -z "$new_wall" ]; then
    new_wall="$(printf "$old_walls\n$all_walls" | sort -h | uniq -u | shuf -n 1)"
    if [ -z "$new_wall" ]; then
      new_wall="$(printf "$old_walls" | head -n 1)"
    fi
    new_wall_with_ratio="$(echo "$new_wall" | sed "s/\(\.[^.]*\)$/@${ratio}\1/")"
  fi


  if [ -f "$WALLPAPER_DIR/${new_wall_with_ratio}" ]; then
    echo "$new_wall_with_ratio"
    hyprctl hyprpaper reload ",$WALLPAPER_DIR/$new_wall_with_ratio" &>/dev/null
    sleep 1

    if hyprctl hyprpaper listloaded | grep -x "$WALLPAPER_DIR/$new_wall_with_ratio" &>/dev/null; then
      break
    fi
  elif [ -f "$WALLPAPER_DIR/${new_wall}" ]; then
    echo "$new_wall"
    hyprctl hyprpaper reload ",$WALLPAPER_DIR/$new_wall" &>/dev/null
    sleep 1

    if hyprctl hyprpaper listloaded | grep -x "$WALLPAPER_DIR/$new_wall" &>/dev/null; then
      break
    fi
  fi

  new_wall=""
done
