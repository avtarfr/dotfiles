#!/usr/bin/env bash
# Yazi wrapper for xdg-desktop-portal-termfilechooser
# Provides seamless file, folder, and save picker dialogs with previews
set -euo pipefail

multiple="${1:-0}"
directory="${2:-0}"
save="${3:-0}"
path="${4:-$HOME}"
out="${5:-/tmp/termfilechooser.portal}"
debug="${6:-0}"

if [ "$debug" = "1" ]; then
    set -x
fi

CONFIG_DIR="$HOME/.config/xdg-desktop-portal-termfilechooser/yazi"
tmp_out="$(mktemp)"
cwd_tmp="$(mktemp)"
created_placeholder=0

# Ensure cleanup on exit
cleanup() {
    rm -f "$tmp_out" "$cwd_tmp"
    if [ "$save" = "1" ] && [ "$created_placeholder" = "1" ] && [ ! -s "$out" ]; then
        rm -f "$target_file" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Resolve starting directory and target file
target_dir="$HOME"
target_file=""

if [ -n "$path" ]; then
    path="${path/#\~/$HOME}"
    if [ -d "$path" ]; then
        target_dir="$path"
    elif [ -f "$path" ]; then
        target_dir="$(dirname "$path")"
        target_file="$path"
    else
        parent="$(dirname "$path")"
        if [ -d "$parent" ]; then
            target_dir="$parent"
        fi
        target_file="$path"
    fi
fi

# Configure window title based on picker mode
title="File Chooser"
if [ "$save" = "1" ]; then
    title="Save File (Select/name file, press Enter to confirm, q to cancel)"
    if [ -n "$target_file" ] && [ ! -e "$target_file" ]; then
        touch "$target_file" 2>/dev/null && created_placeholder=1 || true
    fi
elif [ "$directory" = "1" ]; then
    title="Select Folder (Enter opens folders, 'c' or Shift+Enter selects folder, q to cancel)"
elif [ "$multiple" = "1" ]; then
    title="Select File(s) (Space marks files, Enter confirms, q to cancel)"
else
    title="Select File (Enter to select, q to cancel)"
fi

# Export environment variables for the Yazi chooser profile
export YAZI_CONFIG_HOME="$CONFIG_DIR"
export YAZI_CHOOSER_OUT="$tmp_out"
export YAZI_CHOOSER_DIR_MODE="$directory"

# Launch Kitty modal running Yazi
kitty --class=termfilechooser \
      --title="$title" \
      -o initial_window_width=1100 \
      -o initial_window_height=720 \
      yazi --chooser-file="$tmp_out" --cwd-file="$cwd_tmp" "$target_dir" 2>/dev/null || true

# Process selection
if [ -s "$tmp_out" ]; then
    > "$out"
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        canon="$(realpath "$file" 2>/dev/null || readlink -f "$file" 2>/dev/null || echo "$file")"
        echo "$canon" >> "$out"
    done < "$tmp_out"
    exit 0
elif [ "$directory" = "1" ] && [ -s "$cwd_tmp" ]; then
    dir="$(cat "$cwd_tmp")"
    if [ -d "$dir" ]; then
        canon="$(realpath "$dir" 2>/dev/null || echo "$dir")"
        echo "$canon" > "$out"
        exit 0
    fi
fi

# If no file was chosen (cancelled)
rm -f "$out"
exit 1
