#!/usr/bin/env bash
# wallbash-pywal-full.sh
# Fully patched Pywal-like palette generation in Bash

WALLPAPER="$HOME/Pictures/wallpapers/Balcony-ja.png"
OUTPUT="$HOME/.config/main/wallbash/colors.dcol"
THEME="$HOME/.config/main/wallbash/theme.dcol"
NUM_COLORS=16

mkdir -p "$(dirname "$OUTPUT")" "$(dirname "$THEME")"

# -------------------------
# Helpers
# -------------------------

# Hex → RGBA with fallback
hex_to_rgba() {
    local hex=${1#"#"}
    [[ ${#hex} -ne 6 ]] && hex="000000"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r,$g,$b,1.0)"
}

# Perceptual brightness
brightness() {
    local hex=${1#"#"}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    awk "BEGIN{print int(0.2126*$r + 0.7152*$g + 0.0722*$b)}"
}

# RGB distance
rgb_distance() {
    local hex1=${1#"#"}
    local hex2=${2#"#"}
    local r1=$((16#${hex1:0:2})); local g1=$((16#${hex1:2:2})); local b1=$((16#${hex1:4:2}))
    local r2=$((16#${hex2:0:2})); local g2=$((16#${hex2:2:2})); local b2=$((16#${hex2:4:2}))
    awk "BEGIN{print sqrt(($r1-$r2)^2 + ($g1-$g2)^2 + ($b1-$b2)^2)}"
}

# -------------------------
# Extract colors (working method)
# -------------------------
mapfile -t HEX_COLORS < <(
    magick convert "$WALLPAPER" -resize 50x50! -colors "$NUM_COLORS" +dither -format "%c" histogram:info:- \
        | sort -nr | head -n "$NUM_COLORS" \
        | awk '{gsub("#","",$3); print "#"substr($3,1,6)}'
)

# Ensure we have NUM_COLORS entries
while [ "${#HEX_COLORS[@]}" -lt "$NUM_COLORS" ]; do
    HEX_COLORS+=("#000000")
done

# Debug
echo "Extracted HEX_COLORS:"
printf "%s\n" "${HEX_COLORS[@]}"

# -------------------------
# Assign roles
# -------------------------

# Background: darkest
BG=$(for c in "${HEX_COLORS[@]}"; do echo "$(brightness "$c") $c"; done | sort -n | head -n1 | awk '{print $2}')

# Foreground: max brightness difference from BG
FG=$(for c in "${HEX_COLORS[@]}"; do
    diff=$(( $(brightness "$c") - $(brightness "$BG") ))
    echo "$diff $c"
done | sort -nr | head -n1 | awk '{print $2}')

# Accent: max RGB distance to BG+FG
ACCENT=$(for c in "${HEX_COLORS[@]}"; do
    if [[ "$c" != "$BG" && "$c" != "$FG" ]]; then
        dist1=$(rgb_distance "$c" "$BG")
        dist2=$(rgb_distance "$c" "$FG")
        sum=$(awk "BEGIN{print $dist1+$dist2}")
        echo "$sum $c"
    fi
done | sort -nr | head -n1 | awk '{print $2}')

# Sort remaining colors by brightness
SORTED_COLORS=($(for c in "${HEX_COLORS[@]}"; do echo "$(brightness "$c") $c"; done | sort -n | awk '{print $2}'))

# -------------------------
# Write output
# -------------------------
> "$OUTPUT"
> "$THEME"

for i in $(seq 0 $((NUM_COLORS-1))); do
    hex=${SORTED_COLORS[i]:-#000000}
    rgba=$(hex_to_rgba "$hex")
    echo "\$wallbash.colors$i=$rgba" >> "$OUTPUT"
    echo "wallbash_colors$i=$hex" >> "$THEME"
done

# Foreground / Background / Accent
echo "\$wallbash.background-primary=$(hex_to_rgba "$BG")" >> "$OUTPUT"
echo "\$wallbash.foreground-primary=$(hex_to_rgba "$FG")" >> "$OUTPUT"
echo "\$wallbash.accent-primary=$(hex_to_rgba "$ACCENT")" >> "$OUTPUT"

echo "wallbash_background_primary=$BG" >> "$THEME"
echo "wallbash_foreground_primary=$FG" >> "$THEME"
echo "wallbash_accent_primary=$ACCENT" >> "$THEME"

# Borders: pick colors with max distance to BG
ACTIVE_BORDER=$(for c in "${HEX_COLORS[@]}"; do
    echo "$(rgb_distance "$c" "$BG") $c"
done | sort -nr | head -n1 | awk '{print $2}')

INACTIVE_BORDER=$(for c in "${HEX_COLORS[@]}"; do
    echo "$(rgb_distance "$c" "$BG") $c"
done | sort -nr | sed -n '2p' | awk '{print $2}')

echo "\$wallbash.border-active=$(hex_to_rgba "$ACTIVE_BORDER")" >> "$OUTPUT"
echo "\$wallbash.border-inactive=$(hex_to_rgba "$INACTIVE_BORDER")" >> "$OUTPUT"

echo "wallbash_border_active=$ACTIVE_BORDER" >> "$THEME"
echo "wallbash_border_inactive=$INACTIVE_BORDER" >> "$THEME"

echo "Generated $OUTPUT and $THEME with $WALLPAPER"
