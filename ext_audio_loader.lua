aud_ext = ".mka .mp4a .aac .ogg .ac3 .dts"
sub_ext = ".ass .ssa .srt .sub .jss"

function descriptor()
	return {
		title = "EASL",
		author = "serfreeman1337",
		shortdesc = "EASL",
		description = "This script searches for audio and subtitle files with the same name and loads them",
		url = "https://github.com/kiryanov/ext_audio_loader",
		version = "2.0",
		capabilities = { "input-listener" }
	}
end

function activate()
	slash = package.config:sub(1, 1)
	is_unix = slash == "/"
end

function deactivate()
end

function meta_changed()
end

function input_changed()
	if not vlc.input.is_playing() then
		return
	end

	if vlc.input.item():metas()["sf_autoloaded_from"] == "yes" then
		return
	end

	if vlc.input.item():metas()["sf_autoloaded"] == "yes" then
		local itemid = vlc.input.item():metas()["sf_autoloaded_itemid"]

		if itemid ~= "" then
			itemid = tonumber(itemid)
			vlc.playlist.delete(itemid)
			vlc.input.item():set_meta("sf_autoloaded_itemid", "")
		end

		return
	end

	local uri = vlc.strings.decode_uri(vlc.input.item():uri())
	if not uri:match("^file:///") then
		return
	end
	vlc.msg.dbg("[EASL] Processing " .. uri)
	local file = vlc.input.item():metas()["filename"]
	local name = file:sub(0, (file:len() - get_file_ext(file):len()))
	local dir = uri:sub(8 + (is_unix and 0 or 1), (uri:len() - file:len() - 1))
	vlc.msg.dbg("[EASL] Using name " .. name)
	vlc.msg.dbg("[EASL] Base path " .. dir)
	local opts = {}

	local r = search(dir, name)

	if r ~= nil then
		local fl = ""
		for k, v in pairs(r) do
        		if k == "aud" then
				for i, f in pairs(v) do
					if not is_unix then f = f:gsub("/", slash) end
                                        vlc.msg.dbg("[EASL] Injecting audio " .. f)
					if fl ~= "" then fl = fl .. "#" end
					fl = fl .. vlc.strings.make_uri(f)
				end
			elseif k == "sub" then
				for i, f in pairs(v) do
					if not is_unix then f = f:gsub("/", slash) end
                                        vlc.msg.dbg("[EASL] Injecting subtitle " .. f)
					if fl ~= "" then fl = fl .. "#" end
					fl = fl .. vlc.strings.make_uri(f):gsub("^file:", "file/subtitle:")
				end
			end
		end
		table.insert(opts, "input-slave=" .. fl)
	else
                vlc.msg.dbg("[EASL] Nothing found")
		return
	end

	local item = {{
		path = vlc.input.item():uri(),
		options = opts,
		meta = {
			["sf_autoloaded"] = "yes",
			["sf_autoloaded_itemid"] = tostring(vlc.playlist.current())
		}
	}}

	vlc.input.item():set_meta("sf_autoloaded_from", "yes")
	vlc.playlist.add(item)
end

function get_file_ext(url)
	return url:match("^.+(%..+)$")
end

function is_dir(path)
	local f = vlc.io.open(path, "r")

	if is_unix then
		local ok, err, code = f:read(1)
		f:close()
		return code == 21
	else -- dir is nil on windows
		if f == nil then
			return true
		else
			f:close()
			return false
		end
	end
end

function is_matched(name, with)
	for what in with:gmatch("%S+") do
		if name:find(what, (name:len() - what:len()), true) ~= nil then
			return true
		end
	end
	return false
end

function search(dir, name)
	local dr = vlc.io.readdir(dir)
	if dr == nil then
		return nil
	end
	local r = {}
	local found = false

	for i, content in pairs(dr) do
		-- skip entries starting with a dot
		if content:sub(1, 1) ~= "." then
			local path = dir .. "/" .. content

			if not is_dir(path) then
				-- look for file with the same name
				if content:find(name, 0, true) then
					if is_matched(content, aud_ext) then
						found = true
	                                        vlc.msg.dbg("[EASL] Found matching audio file: " .. path)
                                                if r["aud"] == nil then
							r["aud"] = {}
						end
						table.insert(r["aud"], path)
					elseif is_matched(content, sub_ext) then
						found = true
	                                        vlc.msg.dbg("[EASL] Found matching subtitle file: " .. path)
                                                if r["sub"] == nil then
							r["sub"] = {}
						end
						table.insert(r["sub"], path)
					end
				end
			else -- recursive directory scan
				local rr = search(path, name)

				if rr ~= nil then
					for k, v in pairs(rr) do
						for j, p in pairs(rr[k]) do
							table.insert(r[k], p)
						end
					end
				end
			end
		end
	end

	if found then
		return r
	else
		return nil
	end
end
