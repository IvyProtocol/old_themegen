#!/usr/bin/env bash

# Paths
wallbash_pp="$HOME/.config/wallbash/theme.wallbash"
wallbash_target="$HOME/.config/waybar/Matugen/wbconfgen.css"

# ----------------- Read Wallbash colors -----------------
declare -A wallbash

while IFS='=' read -r key val; do
    [[ -z "$key" || -z "$val" ]] && continue
    wallbash["$key"]="$val"
done < "$wallbash_pp"

# ----------------- Update Kitty config -----------------
tmpfile=$(mktemp)
# Append theme lines using NEW variable structure
{
    echo "@define-color foreground              ${wallbash[wallbash_txt1]};"
    echo "@define-color background              ${wallbash[wallbash_pry1]};"

    echo "@define-color cursor                  ${wallbash[wallbash_pry4]};"

    # black
    echo
    echo "@define-color color0      ${wallbash[wallbash_pry1]};"
    echo "@define-color color8      ${wallbash[wallbash_1xa1]};"

    # red
    echo
    echo "@define-color color1      ${wallbash[wallbash_pry2]};"
    echo "@define-color color9      ${wallbash[wallbash_2xa1]};"

    # green
    echo
    echo "@define-color color2      ${wallbash[wallbash_pry3]};"
    echo "@define-color color10     ${wallbash[wallbash_3xa1]};"

    # yellow
    echo
    echo "@define-color color3      ${wallbash[wallbash_pry4]};"
    echo "@define-color color11     ${wallbash[wallbash_4xa1]};"

    # blue
    echo
    echo "@define-color color4      ${wallbash[wallbash_1xa5]};"
    echo "@define-color color12     ${wallbash[wallbash_1xa6]};"

    # magenta
    echo
    echo "@define-color color5      ${wallbash[wallbash_2xa5]};"
    echo "@define-color color13     ${wallbash[wallbash_2xa7]};"

    # cyan
    echo
    echo "@define-color color6      ${wallbash[wallbash_3xa5]};"
    echo "@define-color color14     ${wallbash[wallbash_3xa7]};"

    # white
    echo
    echo "@define-color color7      ${wallbash[wallbash_4xa5]};"
    echo "@define-color color15     ${wallbash[wallbash_txt1]};"
} >> "$tmpfile"

# Replace original safely
mv "$tmpfile" "$wallbash_target"

$HOME/.config/hypr/scripts/toggle-waybar.sh &
echo "[Wallbash-Waybar] Waybar Color Generation Completed"
