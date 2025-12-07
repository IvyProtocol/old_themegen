##!/usr/bin/env bash
#!/usr/bin/env bash
# wallbash - generate adaptive color palette for Hyprland, kitty, etc.

WALLPAPER="/home/Kroni4/Pictures/wallpapers/wallhaven-qrd6xd_3840x2160.png"
OUTPUT="$HOME/.config/main/wallbash/colors.dcol"
KITTY="$HOME/.config/main/wallbash/theme.conf"

mkdir -p "$(dirname "$OUTPUT")" "$(dirname "$KITTY")"

NUM_COLORS=16

# Hex → RGBA
hex_to_rgba() {
    local hex=${1#"#"}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r,$g,$b,1.0)"
}

# Compute perceived brightness (0..255)
brightness() {
    local hex=${1#"#"}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    awk "BEGIN{print int(0.299*$r + 0.587*$g + 0.114*$b)}"
}

# Extract top NUM_COLORS colors
mapfile -t HEX_COLORS < <(magick convert "$WALLPAPER" -resize 50x50! -colors "$NUM_COLORS" +dither -format "%c" histogram:info:- \
    | sort -nr | head -n "$NUM_COLORS" \
    | awk '{gsub("#","",$3); print "#"substr($3,1,6)}'
)

# Clear old files
> "$OUTPUT"
> "$KITTY"

# Sort colors by brightness (dark → light)
mapfile -t SORTED_COLORS < <(for c in "${HEX_COLORS[@]}"; do
    echo "$(brightness "$c") $c"
done | sort -n | awk '{print $2}')

# Assign roles
DARK_BG=${SORTED_COLORS[0]:-#000000}
LIGHT_FG=${SORTED_COLORS[-1]:-#ffffff}

# Write colors and roles
for i in $(seq 0 $((NUM_COLORS-1))); do
    hex=${HEX_COLORS[i]:-#000000}
    rgba=$(hex_to_rgba "$hex")
    echo "\$wallbash.colors$i=$rgba" >> "$OUTPUT"
    echo "wallbash_colors$i=$rgba" >> "$KITTY"
done

echo "\$wallbash.background-primary=$(hex_to_rgba "$DARK_BG")" >> "$OUTPUT"
echo "\$wallbash.foreground-primary=$(hex_to_rgba "$LIGHT_FG")" >> "$OUTPUT"
echo "wallbash_background_primary=$(hex_to_rgba "$DARK_BG")" >> "$KITTY"
echo "wallbash_foreground_primary=$(hex_to_rgba "$LIGHT_FG")" >> "$KITTY"

# Optional: auto-assign accent (median brightness)
ACCENT=${SORTED_COLORS[$((NUM_COLORS/2))]:-#888888}
echo "\$wallbash.accent-primary=$(hex_to_rgba "$ACCENT")" >> "$OUTPUT"
echo "wallbash_accent_primary=$(hex_to_rgba "$ACCENT")" >> "$KITTY"

echo "Generated $OUTPUT and $KITTY with adaptive scheme from $WALLPAPER"

