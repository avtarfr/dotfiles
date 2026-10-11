local switcher = require("scripts.alttab")

hl.bind("ALT + Tab", switcher.alt_next, { submap_universal = true })
hl.bind("ALT + Alt_L", switcher.alt_close, { release = true, transparent = true })
hl.bind("ALT + Alt_R", switcher.alt_close, { release = true, transparent = true })

hl.bind("SUPER + Tab", switcher.super_next, { submap_universal = true })
hl.bind("SUPER + Super_L", switcher.super_close, { release = true, transparent = true })
hl.bind("SUPER + Super_R", switcher.super_close, { release = true, transparent = true })

hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("XF86RFKill", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/toggle-refresh.sh"))
hl.bind("SUPER + Period", hl.dsp.exec_cmd("~/.local/bin/floating-emote.sh"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("ulauncher-toggle"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("kitty --class=session-modal -o remember_window_size=no --title='Session Manager' -e hypr-session"), { description = "App: Power & Session menu" })
hl.bind("SUPER + A", hl.dsp.exec_cmd("bash -c 'if command -v agy >/dev/null; then kitty --directory ~/Documents --title agy agy; else notify-send -a Antigravity \"Antigravity CLI\" \"Install agy to use this shortcut\"; fi'"), { description = "App: Launch agy CLI" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("~/.local/bin/battery-info"), { description = "System: Battery status & health" })
hl.bind("XF86Battery", hl.dsp.exec_cmd("~/.local/bin/battery-info"), { description = "System: Battery status & health" })
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("ulauncher-toggle"), { flags = "r" })
hl.bind("SUPER + g", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd("~/.local/bin/switchwall"), { description = "Wallpaper: Choose wallpaper" })
hl.bind("CTRL + SUPER + ALT + T", hl.dsp.exec_cmd("~/.local/bin/switchwall --random"), { description = "Wallpaper: Random wallpaper" })
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "App: GUI File manager (Nautilus)" })

-- Win+Shift+1..9: open/focus the corresponding page on the active workspace
for i = 1, 9 do
    local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18 }
    pcall(function() hl.unbind("SUPER + SHIFT + " .. i) end)
    pcall(function() hl.unbind("SUPER + SHIFT + code:" .. numberkey[i]) end)
    hl.bind("SUPER + SHIFT + " .. i, function()
        if scrolldwindle and scrolldwindle.focus_page then
            scrolldwindle.focus_page(i)
        end
    end, { description = "Layout: Open page " .. i })
    hl.bind("SUPER + SHIFT + code:" .. numberkey[i], function()
        if scrolldwindle and scrolldwindle.focus_page then
            scrolldwindle.focus_page(i)
        end
    end)
end

-- Win+Shift+D: Shift screen between dwindle and scroll layout
hl.bind("SUPER + SHIFT + D", function()
    toggle_scroll_shift()
end, { description = "Layout: Shift screen between dwindle and scroll layout" })

-- Win + Arrows: Navigate around vertically (workspaces) and horizontally (pages & quadrants)
pcall(function() hl.unbind("SUPER + Left") end)
pcall(function() hl.unbind("SUPER + Right") end)
pcall(function() hl.unbind("SUPER + Up") end)
pcall(function() hl.unbind("SUPER + Down") end)

hl.bind("SUPER + Left", function()
    if scrolldwindle and scrolldwindle.navigate_direction then
        scrolldwindle.navigate_direction("left")
    end
end, { description = "Navigation: Move left / previous page" })

hl.bind("SUPER + Right", function()
    if scrolldwindle and scrolldwindle.navigate_direction then
        scrolldwindle.navigate_direction("right")
    end
end, { description = "Navigation: Move right / next page" })

hl.bind("SUPER + Up", function()
    if scrolldwindle and scrolldwindle.navigate_direction then
        scrolldwindle.navigate_direction("up")
    end
end, { description = "Navigation: Move up / workspace above" })

hl.bind("SUPER + Down", function()
    if scrolldwindle and scrolldwindle.navigate_direction then
        scrolldwindle.navigate_direction("down")
    end
end, { description = "Navigation: Move down / workspace below" })

-- Scroll tape navigation between pages
hl.bind("SUPER + ALT + Left", function()
    if scrolldwindle and scrolldwindle.scroll_left then scrolldwindle.scroll_left() end
end, { description = "Layout: Scroll to previous page" })
hl.bind("SUPER + ALT + Right", function()
    if scrolldwindle and scrolldwindle.scroll_right then scrolldwindle.scroll_right() end
end, { description = "Layout: Scroll to next page" })

-- Shift window across quadrants and pages
hl.bind("SUPER + SHIFT + Left", function()
    if scrolldwindle and scrolldwindle.shift_window then scrolldwindle.shift_window("left") end
end, { description = "Window: Shift left / previous page" })
hl.bind("SUPER + SHIFT + Right", function()
    if scrolldwindle and scrolldwindle.shift_window then scrolldwindle.shift_window("right") end
end, { description = "Window: Shift right / next page" })
hl.bind("SUPER + SHIFT + Up", function()
    if scrolldwindle and scrolldwindle.shift_window then scrolldwindle.shift_window("up") end
end, { description = "Window: Shift up" })
hl.bind("SUPER + SHIFT + Down", function()
    if scrolldwindle and scrolldwindle.shift_window then scrolldwindle.shift_window("down") end
end, { description = "Window: Shift down" })

-- Native Hyprland Screenshot Utilities (hypr-snip: full, area, swappy editor, scrolling, recording, ocr, lens)
-- Native Hyprland Screenshot Utilities (hypr-snip: full, area, swappy editor, scrolling, recording, ocr, lens)
-- Unbind default and conflicting screenshot/media shortcuts
for _ = 1, 2 do
    pcall(function() hl.unbind("Print") end)
    pcall(function() hl.unbind("SUPER + Print") end)
    pcall(function() hl.unbind("SHIFT + Print") end)
    pcall(function() hl.unbind("CTRL + Print") end)
    pcall(function() hl.unbind("ALT + Print") end)
    pcall(function() hl.unbind("SUPER + ALT + Print") end)
    pcall(function() hl.unbind("SUPER + SHIFT + Print") end)
    pcall(function() hl.unbind("SUPER + CTRL + Print") end)
    pcall(function() hl.unbind("CTRL + SHIFT + Print") end)
    pcall(function() hl.unbind("CTRL + ALT + Print") end)

    pcall(function() hl.unbind("XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("SUPER + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("SHIFT + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("CTRL + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("ALT + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("SUPER + ALT + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("SUPER + SHIFT + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("SUPER + CTRL + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("CTRL + SHIFT + XF86SelectiveScreenshot") end)
    pcall(function() hl.unbind("CTRL + ALT + XF86SelectiveScreenshot") end)

    pcall(function() hl.unbind("Sys_Req") end)
    pcall(function() hl.unbind("SUPER + Sys_Req") end)
    pcall(function() hl.unbind("SHIFT + Sys_Req") end)
    pcall(function() hl.unbind("CTRL + Sys_Req") end)
    pcall(function() hl.unbind("ALT + Sys_Req") end)
    pcall(function() hl.unbind("SUPER + ALT + Sys_Req") end)
    pcall(function() hl.unbind("SUPER + SHIFT + Sys_Req") end)
    pcall(function() hl.unbind("SUPER + CTRL + Sys_Req") end)
    pcall(function() hl.unbind("CTRL + SHIFT + Sys_Req") end)
    pcall(function() hl.unbind("CTRL + ALT + Sys_Req") end)

    pcall(function() hl.unbind("SUPER + SHIFT + S") end)
    pcall(function() hl.unbind("SUPER + SHIFT + P") end)
    pcall(function() hl.unbind("SUPER + SHIFT + E") end)
    pcall(function() hl.unbind("SUPER + SHIFT + A") end)
    pcall(function() hl.unbind("SUPER + SHIFT + R") end)
    pcall(function() hl.unbind("SUPER + SHIFT + T") end)
    pcall(function() hl.unbind("SUPER + CTRL + L") end)
    pcall(function() hl.unbind("CTRL + SUPER + SHIFT + S") end)
    pcall(function() hl.unbind("SUPER + CTRL + SHIFT + S") end)
    pcall(function() hl.unbind("ALT + SUPER + SHIFT + S") end)
    pcall(function() hl.unbind("SUPER + ALT + SHIFT + S") end)
    pcall(function() hl.unbind("CTRL + ALT + SUPER + SHIFT + S") end)
end

-- 1. Interactive Menu: Print / Win+Print (FnLock ON & OFF), Super+Shift+S, Super+Shift+P
hl.bind("Print", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true, description = "Screenshot: Interactive capture menu" })
hl.bind("XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true, description = "Screenshot: Interactive capture menu" })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true, description = "Screenshot: Interactive capture menu" })
hl.bind("SUPER + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true, description = "Screenshot: Interactive capture menu" })
hl.bind("SUPER + Sys_Req", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true, description = "Screenshot: Interactive capture menu" })
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("hypr-snip menu"), { locked = true, description = "Screenshot: Interactive capture menu" })

-- 2. Direct Area Snip: Super + Shift + Print / Super + Shift + XF86 & Super + Shift + A
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("hypr-snip area"), { description = "Screenshot: Direct region selection >> clipboard & file" })
hl.bind("SUPER + SHIFT + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip area"), { description = "Screenshot: Direct region selection >> clipboard & file" })
hl.bind("SUPER + SHIFT + Sys_Req", hl.dsp.exec_cmd("hypr-snip area"), { description = "Screenshot: Direct region selection >> clipboard & file" })
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("hypr-snip area"), { description = "Screenshot: Direct region selection >> clipboard & file" })

-- 3. Swappy Annotation Editor: Shift + Print / Shift + XF86 & Super + Shift + E
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hypr-snip edit"), { description = "Screenshot: Snip & annotate with swappy" })
hl.bind("SHIFT + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip edit"), { description = "Screenshot: Snip & annotate with swappy" })
hl.bind("SHIFT + Sys_Req", hl.dsp.exec_cmd("hypr-snip edit"), { description = "Screenshot: Snip & annotate with swappy" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("hypr-snip edit"), { description = "Screenshot: Snip & annotate with swappy" })

-- 4. Full Desktop Capture: Ctrl + Print / Ctrl + XF86 & Ctrl + PrtSc (FnLock ON)
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hypr-snip full"), { description = "Screenshot: Full desktop >> clipboard & file" })
hl.bind("CTRL + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip full"), { description = "Screenshot: Full desktop >> clipboard & file" })
hl.bind("CTRL + Sys_Req", hl.dsp.exec_cmd("hypr-snip full"), { description = "Screenshot: Full desktop >> clipboard & file" })
hl.bind("CTRL + SUPER + SHIFT + S", hl.dsp.exec_cmd("hypr-snip full"), { description = "Screenshot: Full desktop (FnLock ON)" })

-- 5. Active Window Capture: Alt + Print / Alt + XF86 & Alt + PrtSc (FnLock ON)
hl.bind("ALT + Print", hl.dsp.exec_cmd("hypr-snip window"), { description = "Screenshot: Active window >> clipboard & file" })
hl.bind("ALT + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip window"), { description = "Screenshot: Active window >> clipboard & file" })
hl.bind("ALT + Sys_Req", hl.dsp.exec_cmd("hypr-snip window"), { description = "Screenshot: Active window >> clipboard & file" })
hl.bind("ALT + SUPER + SHIFT + S", hl.dsp.exec_cmd("hypr-snip window"), { description = "Screenshot: Active window (FnLock ON)" })

-- 6. Scrolling Screenshot: Super + Alt + Print / Super + Alt + XF86
hl.bind("SUPER + ALT + Print", hl.dsp.exec_cmd("hypr-snip scroll"), { description = "Screenshot: Scrolling capture" })
hl.bind("SUPER + ALT + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip scroll"), { description = "Screenshot: Scrolling capture" })
hl.bind("SUPER + ALT + Sys_Req", hl.dsp.exec_cmd("hypr-snip scroll"), { description = "Screenshot: Scrolling capture" })

-- 7. Google Lens Search: Super + Ctrl + Print / Super + Ctrl + XF86 & Super + Ctrl + L
hl.bind("SUPER + CTRL + Print", hl.dsp.exec_cmd("hypr-snip lens"), { description = "Search: Google Lens region search" })
hl.bind("SUPER + CTRL + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip lens"), { description = "Search: Google Lens region search" })
hl.bind("SUPER + CTRL + Sys_Req", hl.dsp.exec_cmd("hypr-snip lens"), { description = "Search: Google Lens region search" })
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("hypr-snip lens"), { description = "Search: Google Lens region search" })

-- 8. Screen Recording Toggle: Ctrl + Shift + Print / Ctrl + Shift + XF86 & Super + Shift + R
hl.bind("CTRL + SHIFT + Print", hl.dsp.exec_cmd("hypr-snip record"), { description = "Recording: Toggle region screen recording" })
hl.bind("CTRL + SHIFT + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip record"), { description = "Recording: Toggle region screen recording" })
hl.bind("CTRL + SHIFT + Sys_Req", hl.dsp.exec_cmd("hypr-snip record"), { description = "Recording: Toggle region screen recording" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("hypr-snip record"), { description = "Recording: Toggle region screen recording" })

-- 9. OCR Text Snip: Ctrl + Alt + Print / Ctrl + Alt + XF86 & Ctrl + Alt + PrtSc (FnLock ON)
hl.bind("CTRL + ALT + Print", hl.dsp.exec_cmd("hypr-snip ocr"), { description = "OCR: Snip text >> clipboard" })
hl.bind("CTRL + ALT + XF86SelectiveScreenshot", hl.dsp.exec_cmd("hypr-snip ocr"), { description = "OCR: Snip text >> clipboard" })
hl.bind("CTRL + ALT + Sys_Req", hl.dsp.exec_cmd("hypr-snip ocr"), { description = "OCR: Snip text >> clipboard" })
hl.bind("CTRL + ALT + SUPER + SHIFT + S", hl.dsp.exec_cmd("hypr-snip ocr"), { description = "OCR: Snip text >> clipboard (FnLock ON)" })
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("hypr-snip ocr"), { description = "OCR: Snip text >> clipboard" })

hl.bind("SUPER + V", hl.dsp.exec_cmd("nwg-clipman"))

-- Safe Window Close: targets focused window on current workspace, avoiding closing unfocused windows across workspaces
pcall(function() hl.unbind("SUPER + Q") end)
hl.bind("SUPER + Q", function()
    local act_ws = hl.get_active_workspace()
    local ws_id = act_ws and act_ws.id or 1
    local act_win = hl.get_active_window()
    local target_win = nil

    -- 1. Accept active window ONLY if it belongs to the current workspace
    if act_win and act_win.workspace and act_win.workspace.id == ws_id then
        target_win = act_win
    end

    -- 2. If no valid active window on current workspace, check window under cursor
    if not target_win then
        local pos = hl.get_cursor_pos()
        if pos then
            for _, w in ipairs(hl.get_windows()) do
                if w.workspace and w.workspace.id == ws_id and not w.floating and w.at and w.size then
                    if pos.x >= w.at.x and pos.x <= w.at.x + w.size.x and
                       pos.y >= w.at.y and pos.y <= w.at.y + w.size.y then
                        target_win = w
                        break
                    end
                end
            end
        end
    end

    -- 3. If still not found, check scrolldwindle active page on this workspace
    if not target_win and scrolldwindle and scrolldwindle.get_ws then
        local st = scrolldwindle.get_ws(ws_id)
        if st and st.pages and st.active_page_idx and st.pages[st.active_page_idx] then
            local page = st.pages[st.active_page_idx]
            if page.windows and #page.windows > 0 then
                local target_addr = st.last_focused_addr or page.windows[#page.windows]
                for _, w in ipairs(hl.get_windows()) do
                    if w.address == target_addr then
                        target_win = w
                        break
                    end
                end
                if not target_win then
                    for _, addr in ipairs(page.windows) do
                        for _, w in ipairs(hl.get_windows()) do
                            if w.address == addr then
                                target_win = w
                                break
                            end
                        end
                        if target_win then break end
                    end
                end
            end
        end
    end

    -- 4. Fallback: any non-floating window on current workspace
    if not target_win then
        for _, w in ipairs(hl.get_windows()) do
            if w.workspace and w.workspace.id == ws_id and not w.floating then
                target_win = w
                break
            end
        end
    end

    -- 5. Explicitly focus target_win first, then close it.
    -- STRICT GUARD: NEVER close any window if not on the active workspace!
    if target_win and target_win.workspace and target_win.workspace.id == ws_id then
        hl.dispatch(hl.dsp.focus({ window = target_win }))
        hl.dispatch(hl.dsp.window.close({ window = target_win }))
    end
end, { description = "Window: Close focused window safely" })


