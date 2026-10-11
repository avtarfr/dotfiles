--- @sync entry
local function entry(self, job)
	local h = cx.active.current.hovered
	local sel = cx.active.selected
	local has_sel = false
	if sel then
		for _ in pairs(sel) do
			has_sel = true
			break
		end
	end

	local is_dir_mode = os.getenv("YAZI_CHOOSER_DIR_MODE") == "1"

	-- In file mode, pressing Enter on a directory enters it
	if not has_sel and h and h.cha.is_dir and not is_dir_mode then
		ya.emit("enter", {})
		return
	end

	-- Write selected files or hovered file to output target
	local out = os.getenv("YAZI_CHOOSER_OUT")
	if out and out ~= "" then
		local f = io.open(out, "w")
		if f then
			if has_sel then
				for k, v in pairs(sel) do
					local item = tostring(v)
					if item:find("/") then
						f:write(item .. "\n")
					else
						f:write(tostring(k) .. "\n")
					end
				end
			elseif h then
				f:write(tostring(h.url) .. "\n")
			end
			f:close()
		end
	end

	ya.emit("open", {})
	ya.emit("quit", {})
end

return { entry = entry }
