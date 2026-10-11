#!/usr/bin/env bash
set -euo pipefail

out="${YAZI_CHOOSER_OUT:-/tmp/termfilechooser.portal}"
canon="$(realpath "$PWD" 2>/dev/null || echo "$PWD")"
echo "$canon" > "$out"

ya emit quit 2>/dev/null || true
