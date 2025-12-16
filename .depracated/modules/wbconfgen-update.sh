#!/usr/bin/env bash

# Paths
wallbash_pp="$HOME/.config/wallbash/main/raw-wallbash.dcol"
wallbash_target="$HOME/.config/wallbash/theme.wallbash"

# ----------------- Read Wallbash colors -----------------
declare -A wallbash

while IFS='=' read -r key val; do
    # skip empty lines
    [[ -z "$key" || -z "$val" ]] && continue
    wallbash["$key"]="$val"
done < "$wallbash_pp"

# ----------------- Update Kitty config -----------------
tmpfile=$(mktemp)

# Append theme lines using wallbash variables
{
    echo
    echo "wallbash_pry1=${wallbash[dcol_rrggbb_1]}"
    echo "wallbash_txt1=${wallbash[dcol_rrggbb_2]}"
    echo "wallbash_1xa1=${wallbash[dcol_rrggbb_3]}"
    echo "wallbash_1xa2=${wallbash[dcol_rrggbb_4]}"
    echo "wallbash_1xa3=${wallbash[dcol_rrggbb_5]}"
    echo "wallbash_1xa4=${wallbash[dcol_rrggbb_6]}"
    echo "wallbash_1xa5=${wallbash[dcol_rrggbb_7]}"
    echo "wallbash_1xa6=${wallbash[dcol_rrggbb_8]}"
    echo "wallbash_1xa7=${wallbash[dcol_rrggbb_9]}"
    echo "wallbash_1xa8=${wallbash[dcol_rrggbb_10]}"
    echo "wallbash_1xa9=${wallbash[dcol_rrggbb_11]}"
   
    echo
    echo "wallbash_pry2=${wallbash[dcol_rrggbb_12]}"
    echo "wallbash_txt2=${wallbash[dcol_rrggbb_13]}"
    echo "wallbash_2xa1=${wallbash[dcol_rrggbb_14]}"
    echo "wallbash_2xa2=${wallbash[dcol_rrggbb_15]}"
    echo "wallbash_2xa3=${wallbash[dcol_rrggbb_16]}"
    echo "wallbash_2xa4=${wallbash[dcol_rrggbb_17]}"
    echo "wallbash_2xa5=${wallbash[dcol_rrggbb_18]}"
    echo "wallbash_2xa6=${wallbash[dcol_rrggbb_19]}"
    echo "wallbash_2xa7=${wallbash[dcol_rrggbb_20]}"
    echo "wallbash_2xa8=${wallbash[dcol_rrggbb_21]}"
    echo "wallbash_2xa9=${wallbash[dcol_rrggbb_22]}"
   
    echo
    echo "wallbash_pry3=${wallbash[dcol_rrggbb_23]}"
    echo "wallbash_txt3=${wallbash[dcol_rrggbb_24]}"
    echo "wallbash_3xa1=${wallbash[dcol_rrggbb_25]}"
    echo "wallbash_3xa2=${wallbash[dcol_rrggbb_26]}"
    echo "wallbash_3xa3=${wallbash[dcol_rrggbb_27]}"
    echo "wallbash_3xa4=${wallbash[dcol_rrggbb_28]}"
    echo "wallbash_3xa5=${wallbash[dcol_rrggbb_29]}"
    echo "wallbash_3xa6=${wallbash[dcol_rrggbb_30]}"
    echo "wallbash_3xa7=${wallbash[dcol_rrggbb_31]}"
    echo "wallbash_3xa8=${wallbash[dcol_rrggbb_32]}"
    echo "wallbash_3xa9=${wallbash[dcol_rrggbb_33]}"

    echo
    echo "wallbash_pry4=${wallbash[dcol_rrggbb_34]}"
    echo "wallbash_txt4=${wallbash[dcol_rrggbb_35]}"
    echo "wallbash_4xa1=${wallbash[dcol_rrggbb_36]}"
    echo "wallbash_4xa2=${wallbash[dcol_rrggbb_37]}"
    echo "wallbash_4xa3=${wallbash[dcol_rrggbb_38]}"
    echo "wallbash_4xa4=${wallbash[dcol_rrggbb_39]}"
    echo "wallbash_4xa5=${wallbash[dcol_rrggbb_40]}"
    echo "wallbash_4xa6=${wallbash[dcol_rrggbb_41]}"
    echo "wallbash_4xa7=${wallbash[dcol_rrggbb_42]}"
    echo "wallbash_4xa8=${wallbash[dcol_rrggbb_43]}"
    echo "wallbash_4xa9=${wallbash[dcol_rrggbb_44]}"
    

} >> "$tmpfile"

# Replace original config safely
mv "$tmpfile" "$wallbash_target"

echo "Converted: dcol_* → wallbash_*"






