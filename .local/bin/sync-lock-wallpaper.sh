#!/bin/bash
# Reads hyprpaper's currently active wallpaper and symlinks it for hyprlock
CURRENT=$(hyprctl hyprpaper listactive | head -n1 | cut -d' ' -f2)
ln -sf "$CURRENT" ~/.config/hypr/current_wallpaper
