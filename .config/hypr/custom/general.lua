hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144",
    position = "0x0",
    scale = 1
})

-- Load Custom Scroll-Dwindle Layout
package.loaded["custom.scrolldwindle"] = nil
scrolldwindle = require("custom.scrolldwindle")

-- Load Custom Edge Slow Reveal Navigation
package.loaded["custom.edgescroll"] = nil
edgescroll = require("custom.edgescroll")

-- Enforce custom layout across all workspaces
hl.workspace_rule({
    workspace = "*",
    layout = "lua:scrolldwindle",
})

-- 1. General & Layout Configuration
hl.config({
    general = {
        layout = "lua:scrolldwindle",
    },
    input = {
        follow_mouse = 1,
    },
    cursor = {
        no_warps = true,
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },
    scrolling = {
        column_width = 0.8, -- 80% of main screen in scrolling layout
        focus_fit_method = 0, -- 0 = center, leaving 10% visible on each side
        fullscreen_on_one_column = false,
        follow_focus = true,
        direction = "right",
    },
    decoration = {
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            contrast = 1.3,
            brightness = 1.00,
            new_optimizations = true,
            ignore_opacity = true,
        },
    },
    gestures = {
        workspace_swipe_distance = 250,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true, -- Auto-create new workspace when swiping past the end
        workspace_swipe_invert = true, -- Invert/flip vertical scroll direction
    },
    misc = {
        focus_on_activate = false,
    },
    plugin = {
        scrolloverview = {
            gesture_distance = 40, -- Very low threshold distance for overview gesture
            scale = 0.75,
            workspace_gap = 75,
            layout = "vertical",
            wallpaper = 2,
            blur = true,
            input = {
                touchpad_scroll_factor = 3.5, -- Highly sensitive workspace navigation inside overview
            },
            shadow = {
                enabled = true,
                range = 50,
            },
        },
    },
})

-- Workspace animation: slide vertically (top and bottom)
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 10.0,
    bezier = "emphasizedDecel",
    style = "slidevert"
})
hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 10.0,
    bezier = "emphasizedDecel",
    style = "slidevert"
})
hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 10.0,
    bezier = "emphasizedDecel",
    style = "slidevert"
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 10.0,
    bezier = "emphasizedDecel",
})

-- Custom layout control functions
function toggle_scroll_shift()
    if scrolldwindle and scrolldwindle.toggle_scroll_shift then
        scrolldwindle.toggle_scroll_shift()
    end
end

-- 3. 4-finger vertical swipe to switch workspaces (up and bottom directions)
hl.gesture({
    fingers = 4,
    direction = "vertical",
    action = "workspace",
})

-- 4. 4-finger horizontal swipe to physically slide layout tape in real-time
local gesture_delta_x = 0
local gesture_ws_id = nil

local function on_gesture_finish(e)
    if _G.disable_gestures then
        if scrolldwindle and gesture_ws_id then scrolldwindle.reset_offset(gesture_ws_id) end
        gesture_delta_x = 0
        gesture_ws_id = nil
        return
    end
    if not scrolldwindle or not gesture_ws_id then return end
    if e and e.cancelled then
        scrolldwindle.reset_offset(gesture_ws_id)
        gesture_delta_x = 0
        gesture_ws_id = nil
        return
    end

    local threshold = 75
    if gesture_delta_x < -threshold then
        -- Swiped left -> scroll tape right to reveal next page
        scrolldwindle.commit_offset("right", gesture_ws_id)
    elseif gesture_delta_x > threshold then
        -- Swiped right -> scroll tape left to reveal previous page
        scrolldwindle.commit_offset("left", gesture_ws_id)
    else
        -- Did not cross threshold -> smoothly snap back
        scrolldwindle.reset_offset(gesture_ws_id)
    end
    gesture_delta_x = 0
    gesture_ws_id = nil
end

hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = {
        start = function(e)
            if _G.disable_gestures then return end
            local act_ws = hl.get_active_workspace()
            gesture_ws_id = act_ws and act_ws.id or 1
            gesture_delta_x = 0
            if scrolldwindle and scrolldwindle.set_offset then
                scrolldwindle.set_offset(gesture_ws_id, 0)
            end
        end,
        update = function(e)
            if _G.disable_gestures then return end
            local dx = (e and e.delta and e.delta.x) or (e and e.swipe and e.swipe.delta and e.swipe.delta.x) or 0
            gesture_delta_x = gesture_delta_x + dx
            if scrolldwindle and scrolldwindle.set_offset and gesture_ws_id then
                scrolldwindle.set_offset(gesture_ws_id, gesture_delta_x)
            end
        end,
        finish = on_gesture_finish,
        ["end"] = on_gesture_finish,
    }
})

-- 5. 3-finger swipe to shift windows between quadrants and across pages
local swipe3_dx = 0
local swipe3_dy = 0
local swipe3_active = false

local function on_swipe3_finish(e)
    if _G.disable_gestures then
        swipe3_active = false
        swipe3_dx = 0
        swipe3_dy = 0
        return
    end
    if not swipe3_active then return end
    swipe3_active = false

    if e and e.cancelled then
        swipe3_dx = 0
        swipe3_dy = 0
        return
    end

    local threshold = 60
    local abs_x = math.abs(swipe3_dx)
    local abs_y = math.abs(swipe3_dy)

    if abs_x >= threshold or abs_y >= threshold then
        if scrolldwindle and scrolldwindle.shift_window then
            if abs_x >= abs_y then
                if swipe3_dx > 0 then
                    scrolldwindle.shift_window("right")
                else
                    scrolldwindle.shift_window("left")
                end
            else
                if swipe3_dy > 0 then
                    scrolldwindle.shift_window("down")
                else
                    scrolldwindle.shift_window("up")
                end
            end
        end
    end

    swipe3_dx = 0
    swipe3_dy = 0
end

hl.gesture({
    fingers = 3,
    direction = "swipe",
    action = {
        start = function(e)
            if _G.disable_gestures then return end
            swipe3_dx = 0
            swipe3_dy = 0
            swipe3_active = true
        end,
        update = function(e)
            if _G.disable_gestures then return end
            local dx = (e and e.delta and e.delta.x) or (e and e.swipe and e.swipe.delta and e.swipe.delta.x) or 0
            local dy = (e and e.delta and e.delta.y) or (e and e.swipe and e.swipe.delta and e.swipe.delta.y) or 0
            swipe3_dx = swipe3_dx + dx
            swipe3_dy = swipe3_dy + dy
        end,
        finish = on_swipe3_finish,
        ["end"] = on_swipe3_finish,
    }
})

-- 6. 3-finger tap to toggle Scroll Overview
-- (On Linux/libinput touchpads, 3-finger tap emits middle click: mouse:274)
hl.bind("mouse:274", function()
    if _G.disable_gestures then return end
    hl.plugin.scrolloverview.overview("toggle")
end, { mouse = true })

-- 7. Dynamic Workspace Creation in Scroll Overview

local function table_value(value, ...)
    if value == nil then return nil end
    for _, key in ipairs({ ... }) do
        local ok, item = pcall(function() return value[key] end)
        if ok and item ~= nil then return item end
    end
    return nil
end

local function last_workspace_state()
    local monitor = hl.get_monitor_at_cursor() or hl.get_active_monitor()
    if not monitor then return false, nil end

    local activeWorkspace = table_value(monitor, "active_workspace")
    local activeWorkspaceId = table_value(activeWorkspace, "id")
    if type(activeWorkspaceId) ~= "number" or activeWorkspaceId <= 0 then
        return false, nil
    end

    local activeWorkspaceWindows = table_value(activeWorkspace, "windows")
    if type(activeWorkspaceWindows) ~= "number" or activeWorkspaceWindows == 0 then
        return false, nil
    end

    local lastWorkspaceId
    for _, workspace in ipairs(hl.get_workspaces()) do
        local id = table_value(workspace, "id")
        if type(id) == "number" and id > 0 and table_value(workspace, "special") ~= true and table_value(workspace, "monitor") == monitor then
            lastWorkspaceId = math.max(lastWorkspaceId or id, id)
        end
    end

    return activeWorkspaceId == lastWorkspaceId, monitor
end

local function first_workspace_state()
    local monitor = hl.get_monitor_at_cursor() or hl.get_active_monitor()
    if not monitor then return false, nil, 0 end

    local activeWorkspace = table_value(monitor, "active_workspace")
    local activeWorkspaceId = table_value(activeWorkspace, "id")
    if type(activeWorkspaceId) ~= "number" or activeWorkspaceId <= 0 then
        return false, nil, 0
    end

    local firstWorkspaceId
    for _, workspace in ipairs(hl.get_workspaces()) do
        local id = table_value(workspace, "id")
        if type(id) == "number" and id > 0 and table_value(workspace, "special") ~= true and table_value(workspace, "monitor") == monitor then
            firstWorkspaceId = math.min(firstWorkspaceId or id, id)
        end
    end

    return activeWorkspaceId == firstWorkspaceId, monitor, (firstWorkspaceId or activeWorkspaceId)
end

local function create_workspace_at_end()
    local isLastWorkspace, monitor = last_workspace_state()
    if not isLastWorkspace or not monitor then return end
    hl.dispatch(hl.dsp.focus({ monitor = table_value(monitor, "name") }))
    hl.dispatch(hl.dsp.focus({ workspace = "emptynm" }))
end

local function create_workspace_at_top()
    local isFirstWorkspace, monitor, firstWorkspaceId = first_workspace_state()
    if not isFirstWorkspace or not monitor then return end

    local activeWorkspace = table_value(monitor, "active_workspace")
    local activeWorkspaceWindows = table_value(activeWorkspace, "windows") or 0
    if activeWorkspaceWindows == 0 then return end

    local mon_name = table_value(monitor, "name")

    if firstWorkspaceId > 1 then
        hl.dispatch(hl.dsp.focus({ monitor = mon_name }))
        hl.dispatch(hl.dsp.focus({ workspace = firstWorkspaceId - 1 }))
    else
        local wins = hl.get_windows()
        table.sort(wins, function(a, b)
            local ws_a = (a.workspace and a.workspace.id) or 0
            local ws_b = (b.workspace and b.workspace.id) or 0
            return ws_a > ws_b
        end)
        for _, w in ipairs(wins) do
            if w.workspace and type(w.workspace.id) == "number" and w.workspace.id > 0 and not w.workspace.special then
                local cur_id = w.workspace.id
                hl.exec_cmd(string.format("hyprctl dispatch movetoworkspacesilent %d,address:%s", cur_id + 1, w.address))
            end
        end
        hl.dispatch(hl.dsp.focus({ monitor = mon_name }))
        hl.dispatch(hl.dsp.focus({ workspace = 1 }))
    end
end

local current_top_rule = nil

local function ensure_top_empty_workspace()
    local min_id = nil
    for _, ws in ipairs(hl.get_workspaces()) do
        local id = ws.id
        local wins = ws.windows or 0
        if type(id) == "number" and id > 0 and not ws.special and wins > 0 then
            min_id = math.min(min_id or id, id)
        end
    end

    if not min_id then return end

    if min_id > 1 then
        local target_top_id = min_id - 1
        if target_top_id ~= current_top_rule then
            current_top_rule = target_top_id
            hl.workspace_rule({ workspace = tostring(target_top_id), persistent = false })

            local exists = false
            for _, ws in ipairs(hl.get_workspaces()) do
                if ws.id == target_top_id then exists = true; break end
            end
            if not exists then
                local cur_ws = hl.get_active_workspace()
                local cur_id = cur_ws and cur_ws.id or (target_top_id + 1)
                hl.dispatch(hl.dsp.focus({ workspace = target_top_id }))
                hl.dispatch(hl.dsp.focus({ workspace = cur_id }))
            end
        end
    end
end

-- Only responsible for top-empty-workspace bookkeeping now; the overview's
-- mouse_up/mouse_down/scroll binds are self-contained inside the submap below
-- and no longer need runtime enable/disable toggling.
local function update_workspace_scroll_binds()
    ensure_top_empty_workspace()
end

hl.define_submap("scrolloverview", function()
    -- Keyboard left/right: page through the scrolldwindle tape (not real workspaces,
    -- so the plugin's own navigate() dispatcher can't reach them)
    hl.bind("left", function()
        scrolldwindle.scroll_left()
    end)
    hl.bind("right", function()
        scrolldwindle.scroll_right()
    end)

    -- Click: select the window under the cursor, then confirm/close the overview
    -- (verbatim pattern from the plugin's own Keybind-submap wiki page)
    hl.bind("mouse:272", function()
        hl.plugin.scrolloverview.overview("select")
        hl.plugin.scrolloverview.window("select")
        hl.plugin.scrolloverview.overview("off")
    end, { mouse = true })

    -- Keyboard up/down: real workspaces, or grow a new one at either end
    hl.bind("up", function()
        if first_workspace_state() then
            create_workspace_at_top()
        else
            hl.plugin.scrolloverview.navigate("up")()
        end
    end)
    hl.bind("down", function()
        if last_workspace_state() then
            create_workspace_at_end()
        else
            hl.plugin.scrolloverview.navigate("down")()
        end
    end)

    -- Two-finger / wheel scroll: same as up/down, always live (no enable/disable dance)
    hl.bind("mouse_down", function()
        if last_workspace_state() then
            create_workspace_at_end()
        else
            hl.plugin.scrolloverview.navigate("down")()
        end
    end)
    hl.bind("mouse_up", function()
        if first_workspace_state() then
            create_workspace_at_top()
        else
            hl.plugin.scrolloverview.navigate("up")()
        end
    end)

    hl.bind("return", hl.plugin.scrolloverview.overview("select"))
    hl.bind("escape", hl.plugin.scrolloverview.overview("off"))
end)

hl.on("workspace.active", update_workspace_scroll_binds)
hl.on("workspace.created", update_workspace_scroll_binds)
hl.on("workspace.removed", update_workspace_scroll_binds)
hl.on("workspace.move_to_monitor", update_workspace_scroll_binds)
hl.on("window.open", update_workspace_scroll_binds)
hl.on("window.close", update_workspace_scroll_binds)
hl.on("window.move_to_workspace", update_workspace_scroll_binds)
hl.on("monitor.focused", update_workspace_scroll_binds)
hl.on("keybinds.submap", update_workspace_scroll_binds)

local workspaceScrollTimer = hl.timer(update_workspace_scroll_binds, {
    timeout = 50,
    type = "repeat",
})

update_workspace_scroll_binds()
