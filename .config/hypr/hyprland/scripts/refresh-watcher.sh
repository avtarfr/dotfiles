#!/bin/bash
# Optimized refresh-watcher: only listens to keyboard devices and minimizes CPU overhead

TOGGLE_SCRIPT="$HOME/.config/hypr/hyprland/scripts/toggle-refresh.sh"

# Extract only keyboard devices to completely ignore high-frequency mouse and touchpad events
mapfile -t kbd_devs < <(libinput list-devices 2>/dev/null | awk '/Kernel:/ {dev=$2} /Capabilities:.*keyboard/ {print dev}')

dev_args=()
for dev in "${kbd_devs[@]}"; do
    [[ -c "$dev" ]] && dev_args+=(--device "$dev")
done

# If no keyboard devices found, fallback to default
if [[ ${#dev_args[@]} -eq 0 ]]; then
    dev_args=()
fi

# Stream events through line-buffered grep so bash only wakes up when the key is pressed
libinput debug-events "${dev_args[@]}" | grep --line-buffered -E "REFRESH_RATE_TOGGLE.*pressed" | while read -r _; do
    "$TOGGLE_SCRIPT"
done
