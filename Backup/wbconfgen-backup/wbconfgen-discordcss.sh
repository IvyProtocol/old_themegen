#!/usr/bin/env bash
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
scrDir="$(dirname "$(realpath "$0")")"
thmDcol="$confDir/wallbash/theme-rgba.wallbash"
subTarget="$confDir/vesktop/settings/quickCss.css"
dTheme=$(jq -r '.enabledThemes' "$confDir/vesktop/settings/settings.json")

if [[ -f ${subTarget} ]]; then
  :
else
  echo "
@import url('https://mwittrien.github.io/BetterDiscordAddons/Themes/DiscordRecolor/DiscordRecolor.css');

:root {
  --accentcolor: <wallbash_1xa6_rgb>;
  --accentcolor2: <wallbash_pry2_rgb>;
  --linkcolor: <wallbash_1xa6_rgb>;
  --mentioncolor: <wallbash_1xa5_rgb>;
  --textbrightest: <wallbash_txt1_rgb>;
  --textbrighter: <wallbash_txt2_rgb>;
  --textbright: <wallbash_1xa9_rgb>;
  --textdark: <wallbash_3xa9_rgb>;
  --textdarker: <wallbash_3xa5_rgb>;
  --textdarkest: <wallbash_3xa1_rgb>;

  --backgroundaccent: <wallbash_1xa5_rgb>;
  --backgroundprimary: <wallbash_2xa1_rgb>;
  --backgroundsecondary: <wallbash_pry1_rgb>;
  --backgroundsecondaryalt: <wallbash_pry1_rgb>;
  --backgroundtertiary: <wallbash_pry1_rgb>;
  --backgroundfloating: <wallbash_2xa1_rgb>;;
  --settingsicons: 0;
}

::-webkit-scrollbar {
  width: 10px !important;
}

::-webkit-scrollbar-thumb {
  /* On bigger screens, the scrollbar's border radius falls short, 
  so we put an obscenely large value for the border radius */
  border-radius: 500px !important;
  background: rgba(var(--accentcolor), 0.7) !important;
  background-clip: content-box !important;
  border: 2px solid transparent !important; /* Margin for the scrollbar */
}

/* Any custom CSS below here */
  " >> "$subTarget"
fi

declare -A wallbash

while IFS='=' read -r key val; do
  [[ -z "$key" || -z "$val" ]] && continue
  val="${val//rgba(/}"       
  val="${val//)/}"           
  val="${val%,*}"            
  wallbash["$key"]="$val"
done < "$thmDcol"

rarray=$(jq -r '.enabledThemes[]?' "$confDir/vesktop/settings/settings.json" | tr '[:upper:]' '[:lower:]')

if [[ -n "$rarray" ]]; then
  printf "[Fallback] Detected enabled Vesktop theme(s): %s\n" "$rarray"
  printf "Please disable it/them to run the script again, or use %s/wbconfgen-discordtheme.sh\n" "$scrDir"  exit 0
else
  sed -i "s|--accentcolor: .*;|--accentcolor: ${wallbash[wallbash_1xa6_rgb]};|g" "$subTarget"
  sed -i "s|--accentcolor2: .*;|--accentcolor2: ${wallbash[wallbash_pry2_rgb]};|g" "$subTarget"
  sed -i "s|--linkcolor: .*;|--linkcolor: ${wallbash[wallbash_1xa6_rgb]};|g" "$subTarget"
  sed -i "s|--mentioncolor: .*;|--mentioncolor: ${wallbash[wallbash_1xa5_rgb]};|g" "$subTarget"
  sed -i "s|--textbrightest: .*;|--textbrightest: ${wallbash[wallbash_txt1_rgb]};|g" "$subTarget"
  sed -i "s|--textbrighter: .*;|--textbrighter: ${wallbash[wallbash_txt2_rgb]};|g" "$subTarget"
  sed -i "s|--textbright: .*;|--textbright: ${wallbash[wallbash_1xa9_rgb]};|g" "$subTarget"
  sed -i "s|--textdark: .*;|--textdark: ${wallbash[wallbash_3xa9_rgb]};|g" "$subTarget"
  sed -i "s|--textdarker: .*;|--textdarker: ${wallbash[wallbash_3xa5_rgb]};|g" "$subTarget"
  sed -i "s|--textdarkest: .*;|--textdarkest: ${wallbash[wallbash_3xa1_rgb]};|g" "$subTarget"
  sed -i "s|--backgroundaccent: .*;|--backgroundaccent: ${wallbash[wallbash_1xa5_rgb]};|g" "$subTarget"
  sed -i "s|--backgroundprimary: .*;|--backgroundprimary: ${wallbash[wallbash_2xa1_rgb]};|g" "$subTarget"
  sed -i "s|--backgroundsecondary: .*;|--backgroundsecondary: ${wallbash[wallbash_pry1_rgb]};|g" "$subTarget"
  sed -i "s|--backgroundsecondaryalt: .*;|--backgroundsecondaryalt: ${wallbash[wallbash_pry1]};|g" "$subTarget"
  sed -i "s|--backgroundtertiary: .*;|--backgroundtertiary: ${wallbash[wallbash_pry1]};|g" "$subTarget"
  sed -i "s|--backgroundfloating: .*;|--backgroundfloating: ${wallbash[wallbash_2xa1]};|g" "$subTarget"
  
  sed -i 's/"useQuickCss": .*/"useQuickCss": true,/g' "$confDir/vesktop/settings/settings.json"

  if pgrep -x "vesktop" > /dev/null; then
    wid=$(xdotool search --classname vesktop | head -n1)
    xdtool key --window "$wid" ctrl+r
  else
    echo "[Wallbash] Vesktop isn't running in the process"
  fi
  echo "Vesktop CSS Theme Generation Completed"
  exit 0
fi



