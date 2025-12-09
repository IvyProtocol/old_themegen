#!/usr/bin/env bash

# Paths
wallbash_pp="$HOME/.config/wallbash/theme.wallbash"
wallbash_target="$HOME/.config/kitty/theme.conf"

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
    echo "foreground              ${wallbash[wallbash_txt1]}"
    echo "background              ${wallbash[wallbash_pry1]}"
    echo "background_opacity"     "1.0"
    echo "cursor                  ${wallbash[wallbash_pry4]}"
    echo "cursor_text_color       ${wallbash[wallbash_txt4]}"

    echo
    echo "active_tab_foreground   ${wallbash[wallbash_pry1]}"
    echo "active_tab_background   ${wallbash[wallbash_pry3]}"
    echo "inactive_tab_foreground ${wallbash[wallbash_pry3]}"
    echo "inactive_tab_background ${wallbash[wallbash_pry1]}"
    
    echo
    echo "selection_foreground    ${wallbash[wallbash_pry1]}"
    echo "selection_background    ${wallbash[wallbash_txt1]}"
    
    echo
    echo "active_border_color     ${wallbash[wallbash_pry1]}"
    echo "inactive_border_color   ${wallbash[wallbash_txt1]}"

    # black
    echo
    echo "color0      ${wallbash[wallbash_1xa1]}"
    echo "color8      ${wallbash[wallbash_1xa4]}"

    # red
    echo
    echo "color1      ${wallbash[wallbash_4xa9]}"
    echo "color9      ${wallbash[wallbash_4xa8]}"

    # green
    echo
    echo "color2      ${wallbash[wallbash_2xa9]}"
    echo "color10     ${wallbash[wallbash_2xa8]}"

    # yellow
    echo
    echo "color3      ${wallbash[wallbash_3xa9]}"
    echo "color11     ${wallbash[wallbash_3xa8]}"

    # blue
    echo
    echo "color4      ${wallbash[wallbash_1xa7]}"
    echo "color12     ${wallbash[wallbash_1xa7]}"

    # magenta
    echo
    echo "color5      ${wallbash[wallbash_2xa7]}"
    echo "color13     ${wallbash[wallbash_2xa7]}"

    # cyan
    echo
    echo "color6      ${wallbash[wallbash_3xa7]}"
    echo "color14     ${wallbash[wallbash_3xa7]}"

    # white
    echo
    echo "color7      ${wallbash[wallbash_4xa9]}"
    echo "color15     ${wallbash[wallbash_4xa8]}"
} >> "$tmpfile"

# Replace original safely
mv "$tmpfile" "$wallbash_target"

# reload kitty
killall -SIGUSR1 kitty 2>/dev/null

echo "[Wallbash-Kitty] Kitty Color Generation Completed."

