#!/usr/bin/env bash

# Change to "mpv" if you run mpv directly instead of mpvpaper
PROCESS_NAME="mpvpaper"

update_wallpaper_state() {
    # Get the number of open windows on the currently focused workspace
    local win_count
    win_count=$(hyprctl activeworkspace -j | jq '.windows')

    if [ "$win_count" -gt 0 ]; then
        # Windows exist: freeze playback (0% CPU/GPU usage)
        pkill -STOP -x "$PROCESS_NAME"
    else
        # Workspace is empty: resume playback
        pkill -CONT -x "$PROCESS_NAME"
    fi
}

# Run once at startup
update_wallpaper_state

# Listen to Hyprland's event socket
SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - "UNIX-CONNECT:$SOCKET_PATH" | while read -r event; do
    case "$event" in
        openwindow*|closewindow*|workspace*|focusedmon*|movewindow*)
            update_wallpaper_state
            ;;
    esac
done
