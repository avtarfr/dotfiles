#!/usr/bin/env bash
set -euo pipefail

out="${YAZI_CHOOSER_OUT:-/tmp/termfilechooser.portal}"
dir_mode="${YAZI_CHOOSER_DIR_MODE:-0}"

# If single argument and it's a directory, and not in directory picker mode -> enter directory
if [ $# -eq 1 ] && [ -d "$1" ] && [ "$dir_mode" != "1" ]; then
    ya emit enter 2>/dev/null || true
    exit 0
fi

# Write canonical file paths to output target
> "$out"
for file in "$@"; do
    [ -z "$file" ] && continue
    canon="$(realpath "$file" 2>/dev/null || readlink -f "$file" 2>/dev/null || echo "$file")"
    echo "$canon" >> "$out"
done

ya emit quit 2>/dev/null || true
