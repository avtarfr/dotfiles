#!/bin/bash
# Power watcher: monitors AC adapter status and triggers profile & refresh rate changes

TOGGLE_SCRIPT="$HOME/.config/hypr/hyprland/scripts/toggle-refresh.sh"

# Configurable profile and refresh variables
PROFILE_AC="balanced"
PROFILE_BAT="power-saver"
REFRESH_AC="high"
REFRESH_BAT="low"

get_ac_status() {
    if [[ -f /sys/class/power_supply/ACAD/online ]]; then
        cat /sys/class/power_supply/ACAD/online
    else
        cat /sys/class/power_supply/*/online 2>/dev/null | head -n 1
    fi
}

apply_power_state() {
    local online="$1"
    if [[ "$online" == "1" ]]; then
        # Plugged into AC
        "$TOGGLE_SCRIPT" "$REFRESH_AC" --quiet
        powerprofilesctl set "$PROFILE_AC"
        sudo -n nvidia-smi -rgc 2>/dev/null || true
        notify-send -a "Power Manager" \
            -i ac-adapter \
            -h string:x-canonical-private-synchronous:power_state \
            "AC Connected" "Display: 144Hz | Profile: ${PROFILE_AC}"
    else
        # Running on Battery
        "$TOGGLE_SCRIPT" "$REFRESH_BAT" --quiet
        powerprofilesctl set "$PROFILE_BAT"
        sudo -n nvidia-smi -lgc 210,600 2>/dev/null || true
        notify-send -a "Power Manager" \
            -i battery-low \
            -h string:x-canonical-private-synchronous:power_state \
            "AC Disconnected (Battery)" "Display: 60Hz | Profile: ${PROFILE_BAT}"
    fi
}

# Initial state tracking
prev_state="$(get_ac_status)"

# Listen for kernel uevents on power_supply subsystem
stdbuf -oL udevadm monitor --udev --subsystem-match=power_supply | while read -r _; do
    new_state="$(get_ac_status)"
    if [[ -n "$new_state" && "$new_state" != "$prev_state" ]]; then
        prev_state="$new_state"
        apply_power_state "$new_state"
    fi
done
