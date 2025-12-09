#!/usr/bin/env bash
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
thmDcol="$confDir/wallbash/theme.wallbash"
tarcava="$confDir/cava/config"

declare -A wallbash

while IFS='=' read -r key val; do
    [[ -z "$key" || -z "$val" ]] && continue
    wallbash["$key"]="$val"
done < "$thmDcol"

sed -i "s|gradient_color_1 = .*|gradient_color_1 = \"${wallbash[wallbash_1xa1]}\"|" "$tarcava"
sed -i "s|gradient_color_2 = .*|gradient_color_2 = \"${wallbash[wallbash_1xa2]}\"|" "$tarcava"
sed -i "s|gradient_color_3 = .*|gradient_color_3 = \"${wallbash[wallbash_2xa3]}\"|" "$tarcava"
sed -i "s|gradient_color_4 = .*|gradient_color_4 = \"${wallbash[wallbash_2xa4]}\"|" "$tarcava"
sed -i "s|gradient_color_5 = .*|gradient_color_5 = \"${wallbash[wallbash_3xa5]}\"|" "$tarcava"
sed -i "s|gradient_color_6 = .*|gradient_color_6 = \"${wallbash[wallbash_3xa6]}\"|" "$tarcava"
sed -i "s|gradient_color_7 = .*|gradient_color_7 = \"${wallbash[wallbash_4xa7]}\"|" "$tarcava"
sed -i "s|gradient_color_8 = .*|gradient_color_8 = \"${wallbash[wallbash_4xa8]}\"|" "$tarcava"


pkill -SIGUSR1 cava 2>/dev/null &
echo "[Wallbash-Cava] Cava Generation Completed"
