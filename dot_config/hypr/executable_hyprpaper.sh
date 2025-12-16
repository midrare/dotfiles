#!/usr/bin/env bash

get_monitor_resolution() {
  # hyprland
  if command -v hyprctl >/dev/null 2>&1; then
    hyprland_monitors="$(hyprctl monitors -j 2>/dev/null)"
    if [ -n "${hyprland_monitors}" ]; then
      hyprland_monitor_x="${hyprland_monitors##*\"width\": }"
      hyprland_monitor_x="${hyprland_monitor_x%%,*}"

      hyprland_monitor_y="${hyprland_monitors##*\"height\": }"
      hyprland_monitor_y="${hyprland_monitor_y%%,*}"

      echo "${hyprland_monitor_x} ${hyprland_monitor_y}"
      return 0
    fi
  fi

  echo "0 0"
  return 1
}

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
CACHE_DIR="${XDG_CACHE_HOME:-"$HOME/.cache"}/wallpapers"

monitor_size=$(get_monitor_resolution) || {
  echo "Unable to detect monitor resolution" >&2
  exit 1
}
monitor_width="${monitor_size% *}"
monitor_height="${monitor_size#* }"

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

old_walls="$(hyprctl hyprpaper listloaded | sed -e "s/@[0-9][0-9]*x[0-9][0-9]*//" | rev | cut -d/ -f1 | rev)"
all_walls="$(find "${WALLPAPER_DIR}" -type f | grep -v "@" | grep -i -E ".(png|jpg|jpeg|tiff|gif)$" | rev | cut -d/ -f1 | rev)"
new_wall="$1"

# retry because hyprpaper does not load certain image files for some reason
while true; do
  if [ -z "${new_wall}" ]; then
    new_wall="$(printf "${old_walls}\n${all_walls}" | sort -h | uniq -u | shuf -n 1)"
    if [ -z "${new_wall}" ]; then
      new_wall="$(printf "${old_walls}" | head -n 1)"
    fi

    base="${new_wall%%.*}"
    ext="${new_wall##*.}"
    new_wall_with_size="${base}@${monitor_width}x${monitor_height}.${ext}"
  fi

  if [ ! -f "${CACHE_DIR}/${new_wall_with_size}" ] &&
    [ -f "${WALLPAPER_DIR}/${new_wall%%.*}.json" ]; then
    "$(dirname "${0}")/resize_image.sh" \
      "${WALLPAPER_DIR}/${new_wall}" \
      "${CACHE_DIR}/${new_wall_with_size}" \
      "${WALLPAPER_DIR}/${new_wall%%.*}.json" \
      "${monitor_width}x${monitor_height}" >/dev/null
  fi

  if [ -f "${CACHE_DIR}/${new_wall_with_size}" ]; then
    echo "${new_wall_with_size}"
    hyprctl hyprpaper reload ",${CACHE_DIR}/${new_wall_with_size}" &>/dev/null
    sleep 1

    if hyprctl hyprpaper listloaded | grep -x "${CACHE_DIR}/${new_wall_with_size}" &>/dev/null; then
      break
    fi
  fi

  if [ -f "${WALLPAPER_DIR}/${new_wall}" ]; then
    echo "${new_wall}"
    hyprctl hyprpaper reload ",${WALLPAPER_DIR}/${new_wall}" &>/dev/null
    sleep 1

    if hyprctl hyprpaper listloaded | grep -x "${WALLPAPER_DIR}/${new_wall}" &>/dev/null; then
      break
    fi
  fi

  new_wall=""
done
