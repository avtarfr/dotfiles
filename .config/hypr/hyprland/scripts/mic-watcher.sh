#!/usr/bin/env bash
# Mic mute watcher: monitors PipeWire/PulseAudio events and notifies on mute state change

PIDFILE="/run/user/${UID}/mic-watcher.pid"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi

echo "$$" > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT INT TERM

get_mute_status() {
    pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}'
}

prev_state="$(get_mute_status)"

# Crisp Breeze-dark / Papirus vector icons
ICON_MUTED="mic-off"
ICON_UNMUTED="mic-on"

stdbuf -oL pactl subscribe | while read -r event; do
    case "$event" in
        *"change"*"source"*)
            new_state="$(get_mute_status)"
            if [[ -n "$new_state" && "$new_state" != "$prev_state" ]]; then
                prev_state="$new_state"
                if [[ "$new_state" == "yes" ]]; then
                    notify-send -a "Audio" \
                        -i "$ICON_MUTED" \
                        -h string:x-canonical-private-synchronous:mic_state \
                        -u low \
                        -t 1200 \
                        "Microphone" "Muted"
                else
                    notify-send -a "Audio" \
                        -i "$ICON_UNMUTED" \
                        -h string:x-canonical-private-synchronous:mic_state \
                        -u low \
                        -t 1200 \
                        "Microphone" "Unmuted"
                fi
            fi
            ;;
    esac
done
