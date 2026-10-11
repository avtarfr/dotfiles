#!/bin/bash
# Fires a toast notification on every playerctld status change (play/pause/track change)
# Downloads remote album art to a temp cache since notify-send needs local file paths

CACHE_DIR="/tmp/media-notify-art"
mkdir -p "$CACHE_DIR"

playerctl -p playerctld --follow status 2>/dev/null | while read -r status; do
    title=$(playerctl -p playerctld metadata xesam:title 2>/dev/null)
    artist=$(playerctl -p playerctld metadata xesam:artist 2>/dev/null)
    art_url=$(playerctl -p playerctld metadata mpris:artUrl 2>/dev/null)
    trackid=$(playerctl -p playerctld metadata mpris:trackid 2>/dev/null)

    body="$artist"
    [ -z "$title" ] && title="$status"

    icon_arg=()

    if [[ "$art_url" == file://* ]]; then
        # Already local
        icon_arg=(-i "${art_url#file://}")

    elif [[ "$art_url" == http* ]]; then
        # Remote — cache it keyed by trackid so we don't re-download every event
        safe_id=$(echo -n "$trackid" | md5sum | cut -d' ' -f1)
        cached_file="$CACHE_DIR/$safe_id.jpg"

        if [ ! -s "$cached_file" ]; then
            curl -s -o "$cached_file" "$art_url"
        fi

        [ -s "$cached_file" ] && icon_arg=(-i "$cached_file")
    fi

    notify-send \
        -h string:x-canonical-private-synchronous:media-status \
        -t 3000 \
        "${icon_arg[@]}" \
        "$title" \
        "$status — $body"
done
