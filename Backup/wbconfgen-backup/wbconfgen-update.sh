#!/usr/bin/env bash

# Paths
wallbash_pp="$HOME/.config/main/wallbash/raw-wallbash.dcol"
wallbash_target="$HOME/.config/main/wallbash/theme-wallbash.dcol"

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
    echo "dcol_pry1 = ${wallbash[dcol_rrggbb_1]}"
    echo "dcol_txt1 = ${wallbash[dcol_rrggbb_2]}"
    echo "dcol_1xa1 = ${wallbash[dcol_rrggbb_3]}"
    echo "dcol_1xa2 = ${wallbash[dcol_rrggbb_4]}"
    echo "dcol_1xa3 = ${wallbash[dcol_rrggbb_5]}"
    echo "dcol_1xa4 = ${wallbash[dcol_rrggbb_6]}"
    echo "dcol_1xa5 = ${wallbash[dcol_rrggbb_7]}"
    echo "dcol_1xa6 = ${wallbash[dcol_rrggbb_8]}"
    echo "dcol_1xa7 = ${wallbash[dcol_rrggbb_9]}"
    echo "dcol_1xa8 = ${wallbash[dcol_rrggbb_10]}"
    echo "dcol_1xa9 = ${wallbash[dcol_rrggbb_11]}"
   
    echo
    echo "dcol_pry2 = ${wallbash[dcol_rrggbb_12]}"
    echo "dcol_txt2 = ${wallbash[dcol_rrggbb_13]}"
    echo "dcol_2xa1 = ${wallbash[dcol_rrggbb_14]}"
    echo "dcol_2xa2 = ${wallbash[dcol_rrggbb_15]}"
    echo "dcol_2xa3 = ${wallbash[dcol_rrggbb_16]}"
    echo "dcol_2xa4 = ${wallbash[dcol_rrggbb_17]}"
    echo "dcol_2xa5 = ${wallbash[dcol_rrggbb_18]}"
    echo "dcol_2xa6 = ${wallbash[dcol_rrggbb_19]}"
    echo "dcol_2xa7 = ${wallbash[dcol_rrggbb_20]}"
    echo "dcol_2xa8 = ${wallbash[dcol_rrggbb_21]}"
    echo "dcol_2xa9 = ${wallbash[dcol_rrggbb_22]}"
   
    echo
    echo "dcol_pry3 = ${wallbash[dcol_rrggbb_23]}"
    echo "dcol_txt3 = ${wallbash[dcol_rrggbb_24]}"
    echo "dcol_3xa1 = ${wallbash[dcol_rrggbb_25]}"
    echo "dcol_3xa2 = ${wallbash[dcol_rrggbb_26]}"
    echo "dcol_3xa3 = ${wallbash[dcol_rrggbb_27]}"
    echo "dcol_3xa4 = ${wallbash[dcol_rrggbb_28]}"
    echo "dcol_3xa5 = ${wallbash[dcol_rrggbb_29]}"
    echo "dcol_3xa6 = ${wallbash[dcol_rrggbb_30]}"
    echo "dcol_3xa7 = ${wallbash[dcol_rrggbb_31]}"
    echo "dcol_3xa8 = ${wallbash[dcol_rrggbb_32]}"
    echo "dcol_3xa9 = ${wallbash[dcol_rrggbb_33]}"

    echo
    echo "dcol_pry4 = ${wallbash[dcol_rrggbb_34]}"
    echo "dcol_txt4 = ${wallbash[dcol_rrggbb_35]}"
    echo "dcol_4xa1 = ${wallbash[dcol_rrggbb_36]}"
    echo "dcol_4xa2 = ${wallbash[dcol_rrggbb_37]}"
    echo "dcol_4xa3 = ${wallbash[dcol_rrggbb_38]}"
    echo "dcol_4xa4 = ${wallbash[dcol_rrggbb_39]}"
    echo "dcol_4xa5 = ${wallbash[dcol_rrggbb_40]}"
    echo "dcol_4xa6 = ${wallbash[dcol_rrggbb_41]}"
    echo "dcol_4xa7 = ${wallbash[dcol_rrggbb_42]}"
    echo "dcol_4xa8 = ${wallbash[dcol_rrggbb_43]}"
    echo "dcol_4xa9 = ${wallbash[dcol_rrggbb_44]}"
    

} >> "$tmpfile"

# Replace original config safely
mv "$tmpfile" "$wallbash_target"

echo "Kitty theme updated from Wallbash post-processed palette."

input="$HOME/.config/main/wallbash/theme-wallbash.dcol"
output="$HOME/.config/wallbash/theme.wallbash"

tmp=$(mktemp)

while IFS='=' read -r key val; do
    [[ -z "$key" || -z "$val" ]] && continue

    key="${key//[[:space:]]/}"
    val="${val//[[:space:]]/}"

    if [[ "$key" == dcol_* ]]; then
        new="wallbash_${key#dcol_}"
        echo "$new=$val" >> "$tmp"
    fi
done < "$input"

mv "$tmp" "$output"

echo "Converted: dcol_* → wallbash_*"






