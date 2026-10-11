-- Custom Scroll-Dwindle Layout for Hyprland
-- Layout name: "scrolldwindle" (lua:scrolldwindle)

local M = {}

-- Workspace-isolated state table:
-- ws_state[ws_id] = {
--     pages = { { windows = { addr1, ... }, split_side = "right" } },
--     active_page_idx = 1,
--     last_active_side = "right",
--     scroll_mode = false,
--     last_focused_addr = nil,
-- }
local ws_state = {}

local gaps_in = 4
local gaps_out = 5

local function get_ws(ws_id)
    if not ws_state[ws_id] then
        ws_state[ws_id] = {
            pages = {},
            active_page_idx = 1,
            last_active_side = "right",
            scroll_mode = false,
            last_focused_addr = nil,
        }
    end
    return ws_state[ws_id]
end

-- Helper to find which page a window address belongs to on a specific workspace
local function find_window_page(st, addr)
    for p_idx, page in ipairs(st.pages) do
        for w_idx, a in ipairs(page.windows) do
            if a == addr then
                return p_idx, w_idx
            end
        end
    end
    return nil, nil
end

-- Helper to clean up closed windows for a specific workspace
local function cleanup_pages(st, live_addrs)
    local live_set = {}
    for _, addr in ipairs(live_addrs) do
        live_set[addr] = true
    end

    local new_pages = {}
    for _, page in ipairs(st.pages) do
        local remaining = {}
        for _, addr in ipairs(page.windows) do
            if live_set[addr] then
                table.insert(remaining, addr)
            end
        end
        if #remaining > 0 then
            table.insert(new_pages, {
                windows = remaining,
                split_side = page.split_side or "right"
            })
        end
    end

    st.pages = new_pages
    if #st.pages == 0 then
        st.active_page_idx = 1
        st.scroll_mode = false
        st.last_focused_addr = nil
    else
        st.active_page_idx = math.max(1, math.min(st.active_page_idx, #st.pages))
        if #st.pages > 1 then
            st.scroll_mode = true
        end
    end
end

-- Place windows inside a page bounding box using Dwindle rules
local function place_dwindle_page(targets_map, win_addrs, box, split_side)
    local n = #win_addrs
    if n == 0 then return end

    local x, y, w, h = box.x, box.y, box.w, box.h

    if n == 1 then
        local t = targets_map[win_addrs[1]]
        if t then
            t:place({ x = x, y = y, w = w, h = h })
        end
    elseif n == 2 then
        local half_w = math.floor((w - gaps_in) / 2)
        local t1 = targets_map[win_addrs[1]]
        local t2 = targets_map[win_addrs[2]]
        if t1 then
            t1:place({ x = x, y = y, w = half_w, h = h })
        end
        if t2 then
            t2:place({ x = x + half_w + gaps_in, y = y, w = half_w, h = h })
        end
    elseif n == 3 then
        -- 3 windows: 1 major half (50%), 1 minor half with 2 windows stacked (50% each)
        local half_w = math.floor((w - gaps_in) / 2)
        local half_h = math.floor((h - gaps_in) / 2)

        if split_side == "left" then
            -- Left has 2 stacked, Right has 1
            local t1 = targets_map[win_addrs[1]]
            local t2 = targets_map[win_addrs[2]]
            local t3 = targets_map[win_addrs[3]]
            if t1 then
                t1:place({ x = x, y = y, w = half_w, h = half_h })
            end
            if t2 then
                t2:place({ x = x, y = y + half_h + gaps_in, w = half_w, h = half_h })
            end
            if t3 then
                t3:place({ x = x + half_w + gaps_in, y = y, w = half_w, h = h })
            end
        else
            -- Left has 1, Right has 2 stacked (standard dwindle)
            local t1 = targets_map[win_addrs[1]]
            local t2 = targets_map[win_addrs[2]]
            local t3 = targets_map[win_addrs[3]]
            if t1 then
                t1:place({ x = x, y = y, w = half_w, h = h })
            end
            if t2 then
                t2:place({ x = x + half_w + gaps_in, y = y, w = half_w, h = half_h })
            end
            if t3 then
                t3:place({ x = x + half_w + gaps_in, y = y + half_h + gaps_in, w = half_w, h = half_h })
            end
        end
    elseif n == 4 then
        -- 4 windows: 4 quadrants (2x2 grid)
        -- 1 = Top-Left, 2 = Bottom-Left, 3 = Top-Right, 4 = Bottom-Right
        local half_w = math.floor((w - gaps_in) / 2)
        local half_h = math.floor((h - gaps_in) / 2)
        local t1 = targets_map[win_addrs[1]]
        local t2 = targets_map[win_addrs[2]]
        local t3 = targets_map[win_addrs[3]]
        local t4 = targets_map[win_addrs[4]]

        if t1 then t1:place({ x = x, y = y, w = half_w, h = half_h }) end
        if t2 then t2:place({ x = x, y = y + half_h + gaps_in, w = half_w, h = half_h }) end
        if t3 then t3:place({ x = x + half_w + gaps_in, y = y, w = half_w, h = half_h }) end
        if t4 then t4:place({ x = x + half_w + gaps_in, y = y + half_h + gaps_in, w = half_w, h = half_h }) end
    else
        -- n > 4: 2 columns, evenly distributed rows
        local left_count = math.ceil(n / 2)
        local right_count = n - left_count
        local half_w = math.floor((w - gaps_in) / 2)
        local left_h = math.floor((h - (left_count - 1) * gaps_in) / left_count)
        local right_h = math.floor((h - (right_count - 1) * gaps_in) / right_count)

        for i = 1, left_count do
            local t = targets_map[win_addrs[i]]
            if t then
                t:place({
                    x = x,
                    y = y + (i - 1) * (left_h + gaps_in),
                    w = half_w,
                    h = left_h,
                })
            end
        end
        for i = 1, right_count do
            local t = targets_map[win_addrs[left_count + i]]
            if t then
                t:place({
                    x = x + half_w + gaps_in,
                    y = y + (i - 1) * (right_h + gaps_in),
                    w = half_w,
                    h = right_h,
                })
            end
        end
    end
end

local function recalculate(ctx)
    local targets = ctx.targets
    if not targets or #targets == 0 then
        return
    end

    local area = ctx.area

    -- Determine workspace ID from the first target's window, or active workspace
    local ws_id = nil
    if targets[1] and targets[1].window and targets[1].window.workspace then
        ws_id = targets[1].window.workspace.id
    end
    if not ws_id then
        local act_ws = hl.get_active_workspace()
        ws_id = act_ws and act_ws.id or 1
    end
    local st = get_ws(ws_id)

    -- Map addresses to targets
    local targets_map = {}
    local live_addrs = {}
    for _, t in ipairs(targets) do
        if t.window and t.window.address then
            local addr = t.window.address
            targets_map[addr] = t
            table.insert(live_addrs, addr)
        end
    end

    -- 1. Remove closed windows for this workspace
    cleanup_pages(st, live_addrs)
    if #st.pages > 0 then
        st.active_page_idx = math.max(1, math.min(st.active_page_idx, #st.pages))
    else
        st.active_page_idx = 1
        st.scroll_mode = false
        st.last_focused_addr = nil
        st.offset_x = 0
    end

    local total_win_count = #live_addrs
    if total_win_count <= 1 then
        st.scroll_mode = false
        st.offset_x = 0
        if #st.pages > 1 then
            local all_wins = {}
            for _, p in ipairs(st.pages) do
                for _, a in ipairs(p.windows) do table.insert(all_wins, a) end
            end
            st.pages = { { windows = all_wins, split_side = "right" } }
            st.active_page_idx = 1
        end
    end

    -- 2. Detect which window and side was active on this workspace
    local active_win = hl.get_active_window()
    local active_alive = (active_win and active_win.address and targets_map[active_win.address])

    if active_alive then
        local p_idx, w_idx = find_window_page(st, active_win.address)
        if p_idx then
            if active_win.address ~= st.last_focused_addr then
                st.last_focused_addr = active_win.address
            end

            local page = st.pages[p_idx]
            if page and #page.windows == 2 then
                st.last_active_side = (w_idx == 1) and "left" or "right"
            elseif page and #page.windows == 3 then
                if (page.split_side or "right") == "right" then
                    st.last_active_side = (w_idx == 1) and "left" or "right"
                else
                    st.last_active_side = (w_idx == 3) and "right" or "left"
                end
            end
        end
    else
        -- Active window was closed or invalid: immediately refocus a visible window on the active page
        local cur_page = st.pages[st.active_page_idx]
        if cur_page and #cur_page.windows > 0 then
            local pos = hl.get_cursor_pos()
            local target_addr = cur_page.windows[1]
            if pos then
                for _, addr in ipairs(cur_page.windows) do
                    local t = targets_map[addr]
                    if t and t.window and t.window.at and t.window.size then
                        if pos.x >= t.window.at.x and pos.x <= t.window.at.x + t.window.size.x and
                           pos.y >= t.window.at.y and pos.y <= t.window.at.y + t.window.size.y then
                            target_addr = addr
                            break
                        end
                    end
                end
            end

            st.last_focused_addr = target_addr
        end
    end

    -- 3. Detect unassigned (new) windows
    local unassigned = {}
    for _, addr in ipairs(live_addrs) do
        local p, _ = find_window_page(st, addr)
        if not p then
            table.insert(unassigned, addr)
        end
    end

    -- 4. Process new windows according to Rules 1, 2, 3
    for _, new_addr in ipairs(unassigned) do
        if #st.pages == 0 then
            -- Rule 1: 1st window opens in center taking full screen
            table.insert(st.pages, { windows = { new_addr }, split_side = "right" })
            st.active_page_idx = 1
            st.scroll_mode = false
            st.last_focused_addr = new_addr
        else
            st.active_page_idx = math.max(1, math.min(st.active_page_idx, #st.pages))
            local cur_page = st.pages[st.active_page_idx]

            if #cur_page.windows < 4 then
                -- Join current page (Rule 2 for 2nd window, Rule 3 for 3rd window, Rule 4 for 4 quadrants)
                table.insert(cur_page.windows, new_addr)
                if #cur_page.windows == 3 then
                    cur_page.split_side = st.last_active_side
                end
                st.last_focused_addr = new_addr
            else
                -- 5th window opens -> previous 4 windows STAY in 4 quadrants
                -- Next window goes left or right depending on last_active_side
                if st.last_active_side == "left" then
                    table.insert(st.pages, st.active_page_idx, {
                        windows = { new_addr },
                        split_side = "right"
                    })
                    -- st.active_page_idx stays at this newly inserted page
                else
                    table.insert(st.pages, st.active_page_idx + 1, {
                        windows = { new_addr },
                        split_side = "right"
                    })
                    st.active_page_idx = st.active_page_idx + 1
                end
                -- Scroller immediately makes opened window active and enables scrolling mode
                st.scroll_mode = true
                st.last_focused_addr = new_addr
            end
        end
    end

    -- 5. Calculate layout geometry
    local total_pages = #st.pages
    if total_pages == 0 then return end
    st.active_page_idx = math.max(1, math.min(st.active_page_idx, total_pages))

    local is_scrolling = (st.scroll_mode or total_pages > 1) and (total_win_count > 1)

    local peek_pct = 0.015
    local peek_w = math.floor(area.w * peek_pct)

    local has_left = is_scrolling and (st.active_page_idx > 1)
    local has_right = is_scrolling and (st.active_page_idx < total_pages)

    local main_x, main_w
    if not is_scrolling then
        -- Single window or non-scrolling: occupies 100% full screen
        main_x = area.x
        main_w = area.w
    elseif has_left and has_right then
        -- Windows on BOTH sides: 10% peek left, 80% main, 10% peek right
        main_x = area.x + peek_w
        main_w = area.w - 2 * peek_w
    elseif has_right and not has_left then
        -- Only right window exists: claim back the 10% left space!
        -- Main window starts at left edge and takes 90%, 10% peek on right
        main_x = area.x
        main_w = area.w - peek_w
    elseif has_left and not has_right then
        -- Only left window exists: claim back the 10% right space!
        -- 10% peek on left, main window takes remaining 90% up to right edge
        main_x = area.x + peek_w
        main_w = area.w - peek_w
    else
        main_x = area.x
        main_w = area.w
    end

    st.geometry = {
        has_left = has_left,
        has_right = has_right,
        main_x = main_x,
        main_w = main_w,
        area_x = area.x,
        area_w = area.w,
        peek_w = peek_w,
    }

    local current_offset = is_scrolling and (st.offset_x or 0) or 0

    for p_idx, page in ipairs(st.pages) do
        local page_x
        if not is_scrolling then
            page_x = main_x
        elseif p_idx == st.active_page_idx then
            page_x = main_x + current_offset
        elseif p_idx > st.active_page_idx then
            -- Positioned to the right of the active window
            local base_x = main_x + main_w + (p_idx - st.active_page_idx - 1) * main_w
            page_x = base_x + current_offset
        else
            -- Positioned to the left of the active window
            local base_x = main_x - (st.active_page_idx - p_idx) * main_w
            page_x = base_x + current_offset
        end

        local page_box = {
            x = page_x + gaps_out,
            y = area.y + gaps_out,
            w = main_w - 2 * gaps_out,
            h = area.h - 2 * gaps_out,
        }

        place_dwindle_page(targets_map, page.windows, page_box, page.split_side or "right")
    end
end

-- Keybind action to shift/toggle scroll layout (Rule 2)
function M.toggle_scroll_shift()
    local act_ws = hl.get_active_workspace()
    local ws_id = act_ws and act_ws.id or 1
    local st = get_ws(ws_id)

    if #st.pages == 0 then return end

    st.active_page_idx = math.max(1, math.min(st.active_page_idx, #st.pages))
    local cur_page = st.pages[st.active_page_idx]

    -- If current page has 2 windows, split into 2 separate scrolling screens (Rule 2)
    if cur_page and #cur_page.windows == 2 then
        local w1 = cur_page.windows[1]
        local w2 = cur_page.windows[2]

        local active_win = hl.get_active_window()
        local w2_active = (active_win and active_win.address == w2)

        st.pages[st.active_page_idx] = { windows = { w1 }, split_side = "right" }
        table.insert(st.pages, st.active_page_idx + 1, { windows = { w2 }, split_side = "right" })

        if w2_active then
            st.active_page_idx = st.active_page_idx + 1
            st.last_focused_addr = w2
        else
            st.last_focused_addr = w1
        end

        st.scroll_mode = true
    elseif cur_page and #cur_page.windows == 3 then
        local w1 = cur_page.windows[1]
        local w2 = cur_page.windows[2]
        local w3 = cur_page.windows[3]

        local active_win = hl.get_active_window()
        local target_offset = 0
        local chosen_addr = w1
        if active_win and active_win.address == w2 then
            target_offset = 1
            chosen_addr = w2
        elseif active_win and active_win.address == w3 then
            target_offset = 2
            chosen_addr = w3
        end

        st.pages[st.active_page_idx] = { windows = { w1 }, split_side = "right" }
        table.insert(st.pages, st.active_page_idx + 1, { windows = { w2 }, split_side = "right" })
        table.insert(st.pages, st.active_page_idx + 2, { windows = { w3 }, split_side = "right" })

        st.active_page_idx = st.active_page_idx + target_offset
        st.last_focused_addr = chosen_addr
        st.scroll_mode = true
    elseif cur_page and #cur_page.windows == 1 and #st.pages >= 2 then
        local next_page = st.pages[st.active_page_idx + 1]
        local prev_page = st.pages[st.active_page_idx - 1]
        if next_page and #next_page.windows == 1 then
            table.insert(cur_page.windows, next_page.windows[1])
            table.remove(st.pages, st.active_page_idx + 1)
            if #st.pages == 1 then st.scroll_mode = false end
        elseif prev_page and #prev_page.windows == 1 then
            table.insert(prev_page.windows, cur_page.windows[1])
            table.remove(st.pages, st.active_page_idx)
            st.active_page_idx = st.active_page_idx - 1
            if #st.pages == 1 then st.scroll_mode = false end
        else
            st.scroll_mode = not st.scroll_mode
        end
    else
        st.scroll_mode = not st.scroll_mode
    end

    hl.dispatch(hl.dsp.layout("toggle"))
end

function M.focus_page(p_idx, specific_addr)
    local act_ws = hl.get_active_workspace()
    local ws_id = act_ws and act_ws.id or 1
    local st = get_ws(ws_id)
    if not st or #st.pages == 0 then return end

    if p_idx > #st.pages and #st.pages == 1 and #st.pages[1].windows >= p_idx then
        local cur_page = st.pages[1]
        local all_w = cur_page.windows
        st.pages = {}
        for _, w_addr in ipairs(all_w) do
            table.insert(st.pages, { windows = { w_addr }, split_side = "right" })
        end
        st.scroll_mode = true
    end

    p_idx = math.max(1, math.min(p_idx, #st.pages))
    st.active_page_idx = p_idx

    local page = st.pages[p_idx]
    if page and #page.windows > 0 then
        local target_addr = specific_addr or page.last_focused_addr
        local valid = false
        if target_addr then
            for _, addr in ipairs(page.windows) do
                if addr == target_addr then
                    valid = true
                    break
                end
            end
        end
        if not valid then
            target_addr = page.windows[1]
        end
        st.last_focused_addr = target_addr
        hl.dispatch(hl.dsp.exec_raw("focuswindow", "address:" .. target_addr))
    end

    hl.dispatch(hl.dsp.layout("refresh"))
end

function M.scroll_left()
    local act_ws = hl.get_active_workspace()
    local ws_id = act_ws and act_ws.id or 1
    local st = get_ws(ws_id)
    if st and st.active_page_idx > 1 then
        M.focus_page(st.active_page_idx - 1)
    end
end

function M.scroll_right()
    local act_ws = hl.get_active_workspace()
    local ws_id = act_ws and act_ws.id or 1
    local st = get_ws(ws_id)
    if st then
        if st.active_page_idx < #st.pages or (#st.pages == 1 and st.pages[1] and #st.pages[1].windows > 1) then
            M.focus_page(st.active_page_idx + 1)
        end
    end
end

function M.workspace_move(dir)
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

    if dir == "up" then
        if cur_wins == 0 and cur_id <= min_live_id then return end
        local min_allowed = math.max(1, min_live_id - 1)
        if cur_id <= min_allowed then return end
        hl.dispatch(hl.dsp.focus({ workspace = cur_id - 1 }))
    elseif dir == "down" then
        if cur_wins == 0 and cur_id >= max_live_id then return end
        local max_allowed = max_live_id + 1
        if cur_id >= max_allowed then return end
        hl.dispatch(hl.dsp.focus({ workspace = cur_id + 1 }))
    end
end

function M.navigate_direction(dir)
    if dir == "up" or dir == "down" then
        M.workspace_move(dir)
    elseif dir == "left" then
        M.scroll_left()
    elseif dir == "right" then
        M.scroll_right()
    end
end

M.get_ws = get_ws
M.find_window_page = find_window_page

local function layout_msg(ctx, msg)
    local act_ws = hl.get_active_workspace()
    local ws_id = act_ws and act_ws.id or 1
    local st = get_ws(ws_id)

    if msg == "scroll_left" or msg == "-space" then
        if st.active_page_idx > 1 then
            st.active_page_idx = st.active_page_idx - 1
            local page = st.pages[st.active_page_idx]
            if page and #page.windows > 0 then
                st.last_focused_addr = page.windows[1]
            end
        end
    elseif msg == "scroll_right" or msg == "+space" then
        if st.active_page_idx < #st.pages then
            st.active_page_idx = st.active_page_idx + 1
            local page = st.pages[st.active_page_idx]
            if page and #page.windows > 0 then
                st.last_focused_addr = page.windows[1]
            end
        end
    end
    recalculate(ctx)
    return true
end

-- Guard against follow-mouse hover triggering the peek-window auto-jump
-- below. Peek windows always sit flush against the physical screen edge
-- (that's the point of the peek), so with input.follow_mouse = 1, merely
-- resting the cursor at the edge after ONE dwell/swipe-triggered page
-- change auto-focuses the newly-revealed peek window -- which the code
-- below then reads as "jump active page to match" -- which reveals another
-- peek at the same edge -- which gets auto-focused again, etc. Cursor never
-- moves, so this cascades all the way to the last page. Deliberate page
-- navigation (dwell scroll, 4-finger swipe, keyboard) still works; this
-- only blocks the page jump from firing off passive hover at the edge.
local function cursor_near_screen_edge()
    local pos = hl.get_cursor_pos()
    local mon = hl.get_monitor_at_cursor() or hl.get_active_monitor()
    if not pos or not mon then return false end
    local guard = 28 -- edgescroll's edge_px(4) + release_px(24)
    return pos.x <= mon.x + guard or pos.x >= (mon.x + mon.width) - guard
end

hl.on("window.active", function(win)
    if not win or not win.address then return end
    local ws_id = nil
    if win.workspace and win.workspace.id then
        ws_id = win.workspace.id
    else
        local act_ws = hl.get_active_workspace()
        ws_id = act_ws and act_ws.id or 1
    end

    local st = get_ws(ws_id)
    local p_idx, w_idx = find_window_page(st, win.address)
    if not p_idx then return end

    -- If this window is on a DIFFERENT page than the active page (peeking window):
    if p_idx ~= st.active_page_idx then
        if cursor_near_screen_edge() then
            return
        end
        st.active_page_idx = p_idx
        st.last_focused_addr = win.address
        local page = st.pages[p_idx]
        if page then
            page.last_focused_addr = win.address
        end
        hl.dispatch(hl.dsp.layout("refresh"))
        return
    end

    -- Within the currently active page:
    st.last_focused_addr = win.address
    local page = st.pages[p_idx]
    if page then
        page.last_focused_addr = win.address
        if #page.windows == 2 then
            st.last_active_side = (w_idx == 1) and "left" or "right"
        elseif #page.windows == 3 then
            if (page.split_side or "right") == "right" then
                st.last_active_side = (w_idx == 1) and "left" or "right"
            else
                st.last_active_side = (w_idx == 3) and "right" or "left"
            end
        end
    end
end)

local function resolve_ws(ws_id)
    if not ws_id then
        local act_ws = hl.get_active_workspace()
        return act_ws and act_ws.id or 1
    end
    return ws_id
end

-- Interactive Offset Management for real-time trackpad swipe and mouse Delta X
function M.set_offset(ws_id, offset_x)
    ws_id = resolve_ws(ws_id)
    local st = get_ws(ws_id)
    if #st.pages <= 1 then return end
    st.offset_x = offset_x
    hl.dispatch(hl.dsp.layout("refresh"))
end

function M.commit_offset(direction, ws_id)
    ws_id = resolve_ws(ws_id)
    local st = get_ws(ws_id)
    st.offset_x = 0
    if direction == "right" and st.active_page_idx < #st.pages then
        st.active_page_idx = st.active_page_idx + 1
        local page = st.pages[st.active_page_idx]
        if page and #page.windows > 0 then
            st.last_focused_addr = page.windows[1]
            hl.dispatch(hl.dsp.exec_raw("focuswindow", "address:" .. page.windows[1]))
        end
    elseif direction == "left" and st.active_page_idx > 1 then
        st.active_page_idx = st.active_page_idx - 1
        local page = st.pages[st.active_page_idx]
        if page and #page.windows > 0 then
            st.last_focused_addr = page.windows[1]
            hl.dispatch(hl.dsp.exec_raw("focuswindow", "address:" .. page.windows[1]))
        end
    end
    hl.dispatch(hl.dsp.layout("refresh"))
end

function M.reset_offset(ws_id)
    ws_id = resolve_ws(ws_id)
    local st = get_ws(ws_id)
    if (st.offset_x or 0) ~= 0 then
        st.offset_x = 0
        hl.dispatch(hl.dsp.layout("refresh"))
    end
end

function M.scroll_right(ws_id)
    M.commit_offset("right", ws_id)
end

function M.scroll_left(ws_id)
    M.commit_offset("left", ws_id)
end



if hl.layout and hl.layout.register then
    hl.layout.register("scrolldwindle", {
        recalculate = recalculate,
        layout_msg = layout_msg,
    })
end

function M.shift_window(dir, ws_id)
    ws_id = resolve_ws(ws_id)
    local st = get_ws(ws_id)
    local act_win = hl.get_active_window()
    if not act_win or not act_win.address then return end

    local p_idx, w_idx = find_window_page(st, act_win.address)
    if not p_idx or not w_idx then return end

    local cur_page = st.pages[p_idx]
    if not cur_page then return end

    local n = #cur_page.windows
    local addr = act_win.address

    if n == 1 then
        if dir == "left" then
            if p_idx > 1 then
                table.remove(cur_page.windows, w_idx)
                table.remove(st.pages, p_idx)
                local target_page = st.pages[p_idx - 1]
                table.insert(target_page.windows, addr)
                st.active_page_idx = p_idx - 1
            end
        elseif dir == "right" then
            if p_idx < #st.pages then
                table.remove(cur_page.windows, w_idx)
                table.remove(st.pages, p_idx)
                local target_page = st.pages[p_idx]
                table.insert(target_page.windows, 1, addr)
                st.active_page_idx = p_idx
            end
        end
    elseif n == 2 then
        if w_idx == 1 then -- Left window
            if dir == "right" then
                cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
            elseif dir == "left" then
                table.remove(cur_page.windows, 1)
                if p_idx > 1 then
                    table.insert(st.pages[p_idx - 1].windows, addr)
                    st.active_page_idx = p_idx - 1
                else
                    table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                    st.active_page_idx = 1
                end
            end
        else -- Right window
            if dir == "left" then
                cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
            elseif dir == "right" then
                table.remove(cur_page.windows, 2)
                if p_idx < #st.pages then
                    table.insert(st.pages[p_idx + 1].windows, 1, addr)
                    st.active_page_idx = p_idx + 1
                else
                    table.insert(st.pages, { windows = { addr }, split_side = "right" })
                    st.active_page_idx = #st.pages
                end
            end
        end
    elseif n == 3 then
        local side = cur_page.split_side or "right"
        if side == "right" then
            -- 1 = Left, 2 = Top-Right, 3 = Bottom-Right
            if w_idx == 1 then
                if dir == "right" then
                    cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
                elseif dir == "left" then
                    table.remove(cur_page.windows, 1)
                    if p_idx > 1 then
                        table.insert(st.pages[p_idx - 1].windows, addr)
                        st.active_page_idx = p_idx - 1
                    else
                        table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                        st.active_page_idx = 1
                    end
                end
            elseif w_idx == 2 then
                if dir == "down" then
                    cur_page.windows[2], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[2]
                elseif dir == "left" then
                    cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
                elseif dir == "right" then
                    table.remove(cur_page.windows, 2)
                    if p_idx < #st.pages then
                        table.insert(st.pages[p_idx + 1].windows, 1, addr)
                        st.active_page_idx = p_idx + 1
                    else
                        table.insert(st.pages, { windows = { addr }, split_side = "right" })
                        st.active_page_idx = #st.pages
                    end
                end
            elseif w_idx == 3 then
                if dir == "up" then
                    cur_page.windows[2], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[2]
                elseif dir == "left" then
                    cur_page.windows[1], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[1]
                elseif dir == "right" then
                    table.remove(cur_page.windows, 3)
                    if p_idx < #st.pages then
                        table.insert(st.pages[p_idx + 1].windows, 1, addr)
                        st.active_page_idx = p_idx + 1
                    else
                        table.insert(st.pages, { windows = { addr }, split_side = "right" })
                        st.active_page_idx = #st.pages
                    end
                end
            end
        else
            -- 1 = Top-Left, 2 = Bottom-Left, 3 = Right
            if w_idx == 1 then
                if dir == "down" then
                    cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
                elseif dir == "right" then
                    cur_page.windows[1], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[1]
                elseif dir == "left" then
                    table.remove(cur_page.windows, 1)
                    if p_idx > 1 then
                        table.insert(st.pages[p_idx - 1].windows, addr)
                        st.active_page_idx = p_idx - 1
                    else
                        table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                        st.active_page_idx = 1
                    end
                end
            elseif w_idx == 2 then
                if dir == "up" then
                    cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
                elseif dir == "right" then
                    cur_page.windows[2], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[2]
                elseif dir == "left" then
                    table.remove(cur_page.windows, 2)
                    if p_idx > 1 then
                        table.insert(st.pages[p_idx - 1].windows, addr)
                        st.active_page_idx = p_idx - 1
                    else
                        table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                        st.active_page_idx = 1
                    end
                end
            elseif w_idx == 3 then
                if dir == "left" then
                    cur_page.windows[1], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[1]
                elseif dir == "right" then
                    table.remove(cur_page.windows, 3)
                    if p_idx < #st.pages then
                        table.insert(st.pages[p_idx + 1].windows, 1, addr)
                        st.active_page_idx = p_idx + 1
                    else
                        table.insert(st.pages, { windows = { addr }, split_side = "right" })
                        st.active_page_idx = #st.pages
                    end
                end
            end
        end
    elseif n == 4 then
        -- 1 = Top-Left, 2 = Bottom-Left, 3 = Top-Right, 4 = Bottom-Right
        if w_idx == 1 then
            if dir == "right" then
                cur_page.windows[1], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[1]
            elseif dir == "down" then
                cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
            elseif dir == "left" then
                table.remove(cur_page.windows, 1)
                if p_idx > 1 then
                    table.insert(st.pages[p_idx - 1].windows, addr)
                    st.active_page_idx = p_idx - 1
                else
                    table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                    st.active_page_idx = 1
                end
            end
        elseif w_idx == 2 then
            if dir == "right" then
                cur_page.windows[2], cur_page.windows[4] = cur_page.windows[4], cur_page.windows[2]
            elseif dir == "up" then
                cur_page.windows[1], cur_page.windows[2] = cur_page.windows[2], cur_page.windows[1]
            elseif dir == "left" then
                table.remove(cur_page.windows, 2)
                if p_idx > 1 then
                    table.insert(st.pages[p_idx - 1].windows, addr)
                    st.active_page_idx = p_idx - 1
                else
                    table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                    st.active_page_idx = 1
                end
            end
        elseif w_idx == 3 then
            if dir == "left" then
                cur_page.windows[1], cur_page.windows[3] = cur_page.windows[3], cur_page.windows[1]
            elseif dir == "down" then
                cur_page.windows[3], cur_page.windows[4] = cur_page.windows[4], cur_page.windows[3]
            elseif dir == "right" then
                table.remove(cur_page.windows, 3)
                if p_idx < #st.pages then
                    table.insert(st.pages[p_idx + 1].windows, 1, addr)
                    st.active_page_idx = p_idx + 1
                else
                    table.insert(st.pages, { windows = { addr }, split_side = "right" })
                    st.active_page_idx = #st.pages
                end
            end
        elseif w_idx == 4 then
            if dir == "left" then
                cur_page.windows[2], cur_page.windows[4] = cur_page.windows[4], cur_page.windows[2]
            elseif dir == "up" then
                cur_page.windows[3], cur_page.windows[4] = cur_page.windows[4], cur_page.windows[3]
            elseif dir == "right" then
                table.remove(cur_page.windows, 4)
                if p_idx < #st.pages then
                    table.insert(st.pages[p_idx + 1].windows, 1, addr)
                    st.active_page_idx = p_idx + 1
                else
                    table.insert(st.pages, { windows = { addr }, split_side = "right" })
                    st.active_page_idx = #st.pages
                end
            end
        end
    else
        -- n > 4
        if dir == "left" and w_idx > 1 then
            cur_page.windows[w_idx], cur_page.windows[w_idx - 1] = cur_page.windows[w_idx - 1], cur_page.windows[w_idx]
        elseif dir == "right" and w_idx < n then
            cur_page.windows[w_idx], cur_page.windows[w_idx + 1] = cur_page.windows[w_idx + 1], cur_page.windows[w_idx]
        elseif dir == "left" and w_idx == 1 then
            table.remove(cur_page.windows, 1)
            if p_idx > 1 then
                table.insert(st.pages[p_idx - 1].windows, addr)
                st.active_page_idx = p_idx - 1
            else
                table.insert(st.pages, 1, { windows = { addr }, split_side = "right" })
                st.active_page_idx = 1
            end
        elseif dir == "right" and w_idx == n then
            table.remove(cur_page.windows, n)
            if p_idx < #st.pages then
                table.insert(st.pages[p_idx + 1].windows, 1, addr)
                st.active_page_idx = p_idx + 1
            else
                table.insert(st.pages, { windows = { addr }, split_side = "right" })
                st.active_page_idx = #st.pages
            end
        end
    end

    st.last_focused_addr = addr
    hl.dispatch(hl.dsp.layout("refresh"))
    hl.dispatch(hl.dsp.focus({ window = act_win }))
end

return M
