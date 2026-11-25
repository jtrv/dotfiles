--- @since 26.9.1
-- Total disk usage of the selection (or cwd) via `dust`, shown in the status bar.
-- dust is ~4x faster than fs.calc_size on large trees and counts hardlinks once (matches `du -s`).

local function context_key()
	return tostring(cx.active.current.cwd) .. "\0" .. #cx.active.selected
end

local targets = ya.sync(function()
	local paths = {}
	for _, f in pairs(cx.active.selected) do
		paths[#paths + 1] = tostring(f.url or f)
	end
	if #paths == 0 then
		paths[1] = tostring(cx.active.current.cwd)
	end
	return paths, context_key()
end)

local set_result = ya.sync(function(st, text, key)
	st.text, st.key = text, key
	ui.render()
end)

local function dust_total(paths)
	local output, err = Command("dust")
		:arg({ "-j", "-d", "0", "-P", "-o", "b", "--" })
		:arg(paths)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not output then
		return nil, tostring(err)
	end
	local json = ya.json_decode(output.stdout)
	local bytes = json and type(json.size) == "string" and tonumber(json.size:match("^(%d+)B$"))
	if not bytes then
		return nil, "unexpected dust output: " .. output.stderr
	end
	return bytes
end

local function calc_total(paths)
	local total = 0
	for _, p in ipairs(paths) do
		local it, err = fs.calc_size(Url(p))
		if not it then
			return nil, tostring(err)
		end
		while true do
			local n = it:recv()
			if not n then
				break
			end
			total = total + n
		end
	end
	return total
end

return {
	setup = function(st)
		Status:children_add(function()
			if st.text and st.key == context_key() then
				return ui.Line({ ui.Span(" Σ " .. st.text .. " ") })
			end
			return ""
		end, 450, Status.RIGHT)
	end,

	entry = function()
		local paths, key = targets()
		set_result("…", key)
		local total, err = dust_total(paths)
		if not total then
			total, err = calc_total(paths)
		end
		if not total then
			set_result(nil, nil)
			return ya.notify({ title = "Size", content = err or "failed", timeout = 5, level = "error" })
		end
		set_result(ya.readable_size(total), key)
	end,
}
