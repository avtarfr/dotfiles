#!/bin/bash
# Watches mic and camera usage, fires a notification on start/stop

MIC_STATE=0
CAM_STATE=0

check_mic() {
    # Any active source-output (something reading from mic) means mic in use
    count=$(pactl list source-outputs short 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ] && [ "$MIC_STATE" -eq 0 ]; then
        MIC_STATE=1
        notify-send -h string:x-canonical-private-synchronous:privacy-mic -t 2500 -i microphone-sensitivity-high-symbolic "Microphone" "In use"
    elif [ "$count" -eq 0 ] && [ "$MIC_STATE" -eq 1 ]; then
        MIC_STATE=0
        notify-send -h string:x-canonical-private-synchronous:privacy-mic -t 2500 -i microphone-sensitivity-muted-symbolic "Microphone" "No longer in use"
    fi
}

check_cam() {
    # fuser exits 0 if any process holds the device open
    in_use=0
    for dev in /dev/video*; do
        [ -e "$dev" ] || continue
        if fuser "$dev" >/dev/null 2>&1; then
            in_use=1
            break
        fi
    done

    if [ "$in_use" -eq 1 ] && [ "$CAM_STATE" -eq 0 ]; then
        CAM_STATE=1
        notify-send -h string:x-canonical-private-synchronous:privacy-cam -t 2500 -i camera-web-symbolic "Camera" "In use"
    elif [ "$in_use" -eq 0 ] && [ "$CAM_STATE" -eq 1 ]; then
        CAM_STATE=0
        notify-send -h string:x-canonical-private-synchronous:privacy-cam -t 2500 -i camera-web-symbolic "Camera" "No longer in use"
    fi
}

# Camera has no clean event stream, so poll it lightly
( while true; do check_cam; sleep 2; done ) &

# Mic changes are event-driven via pactl subscribe
pactl subscribe 2>/dev/null | while read -r line; do
    if echo "$line" | grep -q "source-output"; then
        check_mic
    fi
done
