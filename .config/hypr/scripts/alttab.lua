local M = {}

local openedBy = nil

local function object_value(value, key)
    if value == nil then
        return nil
    end
    local ok, result = pcall(function()
        return value[key]
    end)
    return ok and result or nil
end

local function workspace_id()
    return tostring(object_value(hl.get_active_workspace(), "id"))
end

local function window_addr()
    return tostring(object_value(hl.get_active_window(), "address"))
end

local function full_state()
    return workspace_id() .. ":" .. window_addr()
end

local function max_steps()
    return #(hl.get_windows() or {}) + #(hl.get_workspaces() or {}) + 1
end

-- keep navigating in `dir` until state() stops changing
local function go_to_end(dir, state)
    local previous
    for _ = 1, max_steps() do
        local current = state()
        if current == previous then
            return
        end
        previous = current
        hl.plugin.scrolloverview.navigate(dir)
    end
end

local function open(mode)
    hl.config({
        plugin = {
            scrolloverview = {
                layout = "vertical",
                scale = 0.3,
            },
        },
    })
    hl.plugin.scrolloverview.overview("on")
    openedBy = mode
end

-- Alt+Tab: next window in the current workspace, wraps to the first
function M.alt_next()
    open("alt")
    local ws = workspace_id()
    local before = window_addr()
    hl.plugin.scrolloverview.navigate("right")

    if window_addr() == before or workspace_id() ~= ws then
        if workspace_id() ~= ws then
            hl.plugin.scrolloverview.navigate("left")
        end
        go_to_end("left", window_addr)
    end
end

-- Super+Tab: next workspace, wraps to the first
function M.super_next()
    open("super")
    local ws = workspace_id()
    local previous

    -- go down until the workspace actually changes
    for _ = 1, max_steps() do
        hl.plugin.scrolloverview.navigate("down")
        if workspace_id() ~= ws then
            return
        end
        local current = full_state()
        if current == previous then
            break
        end
        previous = current
    end

    -- already on the last workspace, so wrap to the top
    go_to_end("up", full_state)
end

local function close(mode)
    return function()
        if openedBy == mode then
            hl.plugin.scrolloverview.overview("off")
            openedBy = nil
        end
    end
end

M.alt_close = close("alt")
M.super_close = close("super")

return M
