--- @sync entry
local function entry(self, job)
	local out = os.getenv("YAZI_CHOOSER_OUT")
	local cwd = cx.active.current.cwd
	if out and out ~= "" and cwd then
		local f = io.open(out, "w")
		if f then
			f:write(tostring(cwd) .. "\n")
			f:close()
		end
	end
	ya.emit("quit", {})
end

return { entry = entry }
