#!/usr/bin/env bash
set -euo pipefail

# ---------------- Config ----------------
WALLPAPER="/home/Kroni4/Pictures/wallpapers/wallhaven-qrd6xd_3840x2160.png"
PY_WORKER="$HOME/.config/main/parsing/wbconfgen.py"
OUT_DIR="$HOME/.config/main/wallbash"

THEME_FILE="$OUT_DIR/theme.dcol"
COLORS_FILE="$OUT_DIR/colors.dcol"

GROUPS=4

WORKERS=4
ACCENTS=9

# ---------------- Prep ----------------
mkdir -p "$OUT_DIR"

if [ ! -x "$PY_WORKER" ]; then
  echo "Python worker missing or not executable: $PY_WORKER" >&2
  exit 1
fi

export WALLPAPER

# ---------------- Run Python ----------------
echo "Generating color palette for wallpaper: $WALLPAPER"
python3 "$PY_WORKER" "$WALLPAPER"
$HOME/.config/main/wbconfgmodules/wbconfgen-kitty.py
pkill -SIGUSR1 kitty
$HOME/.config/main/parsing/wbconfgen-softcom.sh

# ---------------- Done ----------------
if [ -f "$THEME_FILE" ] && [ -f "$COLORS_FILE" ]; then
    echo "Successfully generated:"
    echo "   Theme:  $THEME_FILE"
    echo "   Colors: $COLORS_FILE"
else
    echo "Something went wrong. Files not found."
fi

