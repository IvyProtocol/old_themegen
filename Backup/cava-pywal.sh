#!/bin/bash

# Paths
CAVA_CONFIG="$HOME/.config/cava/config"
WAL_COLORS="$HOME/.cache/wal/colors.json"

# Take colors from pywal
COLOR1=$(jq -r '.colors.color10' "$WAL_COLORS")
COLOR2=$(jq -r '.colors.color0' "$WAL_COLORS")
COLOR3=$(jq -r '.colors.color13' "$WAL_COLORS")

# Update colors in CAVA
sed -i "s|^gradient_color_1 = '.*'|gradient_color_1 = '$COLOR1'|" "$CAVA_CONFIG"
sed -i "s|^gradient_color_2 = '.*'|gradient_color_2 = '$COLOR3'|" "$CAVA_CONFIG"
sed -i "s|^gradient_color_3 = '.*'|gradient_color_3 = '$COLOR2'|" "$CAVA_CONFIG"

# Auto-Restart CAVA (if it's running)
killall -USR1 cava
