#!/usr/bin/env bash

# Paths
wallbash_pp="$HOME/.config/wallbash/templates/theme.conf"
wallbash_target="$HOME/.config/kitty/theme.conf"

# ----------------- Read Wallbash colors -----------------
declare -A wallbash

while IFS='=' read -r key val; do
    # skip empty lines
    [[ -z "$key" || -z "$val" ]] && continue
    wallbash["$key"]="$val"
done < "$wallbash_pp"

# ----------------- Update Kitty config -----------------
tmpfile=$(mktemp)

# Remove old theme lines while keeping other content intact
grep -v -E '^(foreground|background|cursor|active_tab_foreground|active_tab_background|inactive_tab_foreground|inactive_tab_background|active_border_color|inactive_border_color|bell_border_color|color[0-9]+)' "$wallbash_target" > "$tmpfile"

# Append theme lines using wallbash variables
{
    echo "foreground         ${wallbash[wallbash_atfx1]}"
    echo "background         ${wallbash[wallbash_bgx1]}"
    echo "background_opacity 1.0"
    echo "cursor             ${wallbash[wallbash_crx1]}"

    echo "active_tab_foreground     ${wallbash[wallbash_atfx1]}"
    echo "active_tab_background     ${wallbash[wallbash_atbx1]}"
    echo "inactive_tab_foreground   ${wallbash[wallbash_itfx1]}"
    echo "inactive_tab_background   ${wallbash[wallbash_itbx1]}"

    echo "active_border_color   ${wallbash[wallbash_apx1]}"
    echo "inactive_border_color ${wallbash[wallbash_appx1]}"
    echo "bell_border_color     ${wallbash[wallbash_bbx1]}"

    # Map pry1–pry16 to color0–color15 (adjust as needed)
    echo "color0       ${wallbash[wallbash_pry1]}"
    echo "color8       ${wallbash[wallbash_pry9]}"
    echo "color1       ${wallbash[wallbash_pry2]}"
    echo "color9       ${wallbash[wallbash_pry10]}"
    echo "color2       ${wallbash[wallbash_pry3]}"
    echo "color10      ${wallbash[wallbash_pry3]}"
    echo "color3       ${wallbash[wallbash_pry4]}"
    echo "color11      ${wallbash[wallbash_pry4]}"
    echo "color4       ${wallbash[wallbash_pry5]}"
    echo "color12      ${wallbash[wallbash_pry5]}"
    echo "color5       ${wallbash[wallbash_pry6]}"
    echo "color13      ${wallbash[wallbash_pry6]}"
    echo "color6       ${wallbash[wallbash_pry7]}"
    echo "color14      ${wallbash[wallbash_pry7]}"
    echo "color7       ${wallbash[wallbash_pry8]}"
    echo "color15      ${wallbash[wallbash_pry8]}"
} >> "$tmpfile"

# Replace original config safely
mv "$tmpfile" "$wallbash_target"

echo "Kitty theme updated from Wallbash post-processed palette."

