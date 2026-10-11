#!/bin/bash
# Configurable variables
OUTPUT="eDP-1"
RESOLUTION="1920x1080"
LOW_RATE="60.000999"
HIGH_RATE="144.001007"

target_arg="${1:-toggle}"
quiet_mode=false

for arg in "$@"; do
    case "$arg" in
        -q|--quiet) quiet_mode=true ;;
    esac
done

# Get current refresh rate
current_raw=$(wlr-randr --output "$OUTPUT" 2>/dev/null | grep "current" | grep -oP '\d+\.\d+')

case "$target_arg" in
    60|low|power-saver)
        target_rate="$LOW_RATE"
        target_label="60 Hz"
        ;;
    144|high|performance|balanced)
        target_rate="$HIGH_RATE"
        target_label="144 Hz"
        ;;
    toggle|*)
        if (( $(echo "${current_raw:-0} > 100" | bc -l) )); then
            target_rate="$LOW_RATE"
            target_label="60 Hz"
        else
            target_rate="$HIGH_RATE"
            target_label="144 Hz"
        fi
        ;;
esac

# Avoid unnecessary screen re-mode if already at target rate
diff=$(echo "${current_raw:-0} - $target_rate" | bc -l 2>/dev/null | tr -d '-')
if [[ -z "$diff" ]] || (( $(echo "$diff > 0.5" | bc -l) )); then
    wlr-randr --output "$OUTPUT" --mode "${RESOLUTION}@${target_rate}"
fi

# Send desktop notification if not silenced
if [[ "$quiet_mode" != true ]]; then
    notify-send -a "Display" \
        -i video-display \
        -h string:x-canonical-private-synchronous:refresh_rate \
        "Display Refresh Rate" "Switched to ${target_label}"
fi
