#!/usr/bin/env bash

# 1. Fire up the emoji picker binary in the background
emote &

# 2. Give the window engine up to 1 second to create the application window layer
for i in {1..20}; do
    # Check if the Emote window is active on screen
    if hyprctl activewindow | grep -q "class: Emote"; then
        # Fetch the exact hardware cursor coordinates and strip commas
        POS=$(hyprctl cursorpos | tr -d ',')
        X=$(echo "$POS" | awk '{print $1}')
        Y=$(echo "$POS" | awk '{print $2}')

        # 3. Use the live moveactive dispatcher to center it exactly at the cursor point
        # (Emote is roughly 400x350px. Offsetting by -200x and +20y centers it cleanly right below your text caret)
        hyprctl dispatch moveactive exact $((X - 200)) $((Y + 20))
        break
    fi
    sleep 0.05
done
