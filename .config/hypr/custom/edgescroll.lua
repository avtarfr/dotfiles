-- Edge Slow Reveal Navigation for Hyprland
-- Provides non-hot-corner deliberate dwell edge scrolling:
-- 1. Horizontal (left/right screen edges): Pushing into the physical display edge for >300ms
--    scrolls the custom scrolldwindle layout tape ONE page (single-shot, non-repeating --
--    move the cursor well clear of the edge and back to reveal another page).
-- 2. Vertical (top/bottom screen edges): Pushing into the top/bottom display edge for >500ms
--    slides between workspaces vertically with full visibility (single-shot, strictly non-cycling).

local M = {}

M.enabled = true
M.horiz_dwell_ticks = 6   -- 300ms (6 * 50ms)
M.vert_dwell_ticks = 6    -- 300ms (6 * 50ms)
M.corner_margin = 40      -- pixels from corners to ignore (prevents corner misfires)
M.edge_px = 4             -- detection threshold from physical display edge in pixels (fires here)
M.release_px = 24         -- must clear this far from the edge before it can fire again (kills jitter re-trigger)

local edge_state = {
    current_edge = nil,
    dwell_ticks = 0,
    locked_edge = nil,  -- edge that just fired; held until cursor clears M.release_px
}

-- Distance (in px) the cursor currently is from the given physical edge.
local function edge_distance(pos, mon, edge)
    if edge == "left" then return pos.x - mon.x
    elseif edge == "right" then return (mon.x + mon.width) - pos.x
    elseif edge == "top" then return pos.y - mon.y
    elseif edge == "bottom" then return (mon.y + mon.height) - pos.y
    end
    return math.huge
end

local function trigger_scroll(edge)
    if not M.enabled or _G.disable_gestures then return end
    if edge == "right" then
        if scrolldwindle and scrolldwindle.scroll_right then
            scrolldwindle.scroll_right()
        end
    elseif edge == "left" then
        if scrolldwindle and scrolldwindle.scroll_left then
            scrolldwindle.scroll_left()
        end
    elseif edge == "top" or edge == "bottom" then
        local act_ws = hl.get_active_workspace()
        if not act_ws then return end
        local cur_id = act_ws.id
        local cur_wins = act_ws.windows or 0

        local min_live_id, max_live_id = nil, nil
        for _, ws in ipairs(hl.get_workspaces()) do
            local id = ws.id
            local wins = ws.windows or 0
            if type(id) == "number" and id > 0 and not ws.special and wins > 0 then
                min_live_id = math.min(min_live_id or id, id)
                max_live_id = math.max(max_live_id or id, id)
            end
        end

        min_live_id = min_live_id or cur_id
        max_live_id = max_live_id or cur_id

        if edge == "top" then
            -- If already on an empty workspace at or above the top live workspace: STOP
            if cur_wins == 0 and cur_id <= min_live_id then return end
            -- Strictly allow at most ONE empty workspace at top: min_live_id - 1
            local min_allowed = math.max(1, min_live_id - 1)
            if cur_id <= min_allowed then return end
            hl.dispatch(hl.dsp.focus({ workspace = cur_id - 1 }))
        elseif edge == "bottom" then
            -- If already on an empty workspace at or below the bottom live workspace: STOP
            if cur_wins == 0 and cur_id >= max_live_id then return end
            -- Strictly allow at most ONE empty workspace at bottom: max_live_id + 1
            local max_allowed = max_live_id + 1
            if cur_id >= max_allowed then return end
            hl.dispatch(hl.dsp.focus({ workspace = cur_id + 1 }))
        end
    end
end

local function check_edge_scroll()
    if not M.enabled then return end

    local submap = hl.get_current_submap()
    if submap and submap ~= "" then return end

    local act_ws = hl.get_active_workspace()
    if act_ws and act_ws.has_fullscreen then return end

    local pos = hl.get_cursor_pos()
    local mon = hl.get_monitor_at_cursor() or hl.get_active_monitor()
    if not pos or not mon then return end

    -- If we just fired on an edge, keep it locked out until the cursor has
    -- actually moved M.release_px clear of that edge. Without this, a page
    -- change (which refocuses a window right at the same edge) can cause a
    -- one-tick blip in/out of the tiny edge_px detection zone, which resets
    -- dwell_ticks and lets it climb back to threshold and fire again almost
    -- immediately -- i.e. the "infinite scroll to the last page" bug.
    if edge_state.locked_edge then
        if edge_distance(pos, mon, edge_state.locked_edge) >= M.release_px then
            edge_state.locked_edge = nil
        else
            edge_state.current_edge = nil
            edge_state.dwell_ticks = 0
            return
        end
    end

    local min_x, max_x = mon.x, mon.x + mon.width
    local min_y, max_y = mon.y, mon.y + mon.height
    local corner = M.corner_margin
    local thresh = M.edge_px

    local detected = nil
    if pos.y > min_y + corner and pos.y < max_y - corner then
        if pos.x <= min_x + thresh then detected = "left"
        elseif pos.x >= max_x - thresh then detected = "right" end
    end
    if not detected and pos.x > min_x + corner and pos.x < max_x - corner then
        if pos.y <= min_y + thresh then detected = "top"
        elseif pos.y >= max_y - thresh then detected = "bottom" end
    end

    if not detected then
        edge_state.current_edge = nil
        edge_state.dwell_ticks = 0
        return
    end

    if detected ~= edge_state.current_edge then
        edge_state.current_edge = detected
        edge_state.dwell_ticks = 0
    end

    edge_state.dwell_ticks = edge_state.dwell_ticks + 1
    local threshold = (detected == "top" or detected == "bottom") and M.vert_dwell_ticks or M.horiz_dwell_ticks

    if edge_state.dwell_ticks == threshold then
        trigger_scroll(detected)
        edge_state.locked_edge = detected
        edge_state.current_edge = nil
        edge_state.dwell_ticks = 0
    end
end
-- Guard against duplicate timers piling up across config reloads (each
-- reload re-requires this module from scratch via package.loaded[...] = nil,
-- which used to spawn a brand new hl.timer every time without killing the
-- previous one -- multiple overlapping timers is what "infinite scroll that
-- never fully stops" actually was).
if _G.__edgescroll_active_timer then
    pcall(function() _G.__edgescroll_active_timer:stop() end)
    pcall(function() _G.__edgescroll_active_timer:cancel() end)
    pcall(function() _G.__edgescroll_active_timer.enabled = false end)
end

M.timer = hl.timer(check_edge_scroll, {
    timeout = 50,
    type = "repeat",
})
_G.__edgescroll_active_timer = M.timer

M.get_state = function() return edge_state end
M.set_enabled = function(val) M.enabled = val end

return M
