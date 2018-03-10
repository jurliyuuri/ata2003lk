local mode = {}
local larstack = {}
local larcount = 0
local infile, outfile, err

local function write(str, ws)
	if str == "zali" then
		table.insert(mode, 1)
		return outfile:write("nta 4 f5 krz ")
	elseif str == "ycax" then
		return outfile:write("ata 4 f5" .. ws)
	elseif str == "fenx" then
		table.insert(mode, 2)
		return outfile:write("nta 4 f5 inj ")
	elseif str == "cers" then
		return outfile:write("nll ")
	elseif str == "dosn" then
		return outfile:write("krz f5@ xx" .. ws)
	elseif str == "lar" then
		table.insert(mode, 3)

		larcount = larcount + 1
		table.insert(larstack, larcount)
		return outfile:write("nll lar" .. tostring(larcount) .. " fi" .. ws)
	elseif str == "xtlo" or str == "xtlonys" or str == "xylo" or str == "xylonys"
		or str == "clo" or str == "niv"
		or str == "llo" or str == "llonys" or str == "xolo" or str == "xolonys" then
		if #mode > 0 and mode[#mode] == 3 then
			table.remove(mode)
			return outfile:write(str .. " malkrz lar-sit" .. tostring(larstack[#larstack]) .. " xx" .. ws)
		else
			return outfile:write(str .. ws)
		end
	elseif str == "ral" then
		if #larstack == 0 then
			return nil, "Mismatch: '" .. str .. "'"
		end

		local count = table.remove(larstack)
		return outfile:write("krz lar" .. tostring(count) .. " xx\n"
			.. "nll lar-sit" .. tostring(count) .." fen " .. ws)
	elseif str ~= "" then
		local v = str

		local usestack = string.match(v, "^s@(.+)")
		if usestack ~= nil then
			v = "f5+" .. usestack .. "@"
		end

		local m = table.remove(mode)
		if m == 1 then
			v = v .. " f5@" .. ws
		elseif m == 2 then
			v = v .. " xx f5@ ata 4 f5" .. ws
		else
			table.insert(mode, m)
			v = v .. ws
		end

		return outfile:write(v)
	else
		return outfile, nil
	end
end

function transpile(filename)
	infile, err = io.open(filename, "r")
	if infile == nil then
		print("error (infile): " .. tostring(err))
		os.exit(1)
	end

	outfile, err = io.open(filename .. ".lk", "w")
	if outfile == nil then
		print("error (outfile): " .. tostring(err))
		os.exit(1)
	end

	local buf = ""
	local comment = false

	outfile:write("'i'c\n")
	for c in infile:lines(1) do
		if c == ";" then
			comment = not comment
		elseif not comment then
			if c == "\t" then
				c = " "
			end

			if c == "\n" or c == '\r' or c == " " then
				outfile, err = write(buf, c)
				if outfile == nil then
					print("error (transpile) : " .. tostring(err))
					if #mode == 0 then
						print("mode stack: ")
					else
						print("mode stack: " .. table.concat(mode, ","));
					end
					if #larstack == 0 then
						print("lar stack: ")
					else
						print("lar stack: " .. table.concat(larstack, ","));
					end
					os.exit(1)
				end

				buf = ""
			else
				buf = buf .. c
			end
		end
	end

	infile:close()
	outfile:close()
end

transpile(arg[1])

