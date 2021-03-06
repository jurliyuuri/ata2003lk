require("utils")

local function isregister(str)
    return str == "f0" or str == "f1" or str == "f2"
        or str == "f3" or str == "f5"
end

function readfile(filename)
    local words = {}
    local infile, err = io.open(filename, "r")

    if infile == nil then
        print("error (infile): " .. tostring(err))
        os.exit(1)
    end

    local buf = ""
    local comment = false
    for c in infile:lines(1) do
        if c == ";" then
            if comment then
                comment = false
            else
                if string.match(buf, "[+|]$") ~= nil then
                    -- 何もしない
                elseif buf ~= "" then
                    table.insert(words, buf)
                    buf = ""
                end
                comment = true
            end
        elseif not comment then
            if c == "\t" then
                c = " "
            end

            if c == " " or c == "\r" or c == "\n" then
                if string.match(buf, "[+|]$") ~= nil then
                    -- 何もしない
                elseif buf ~= "" then
                    table.insert(words, buf)
                    buf = ""
                end
            elseif c == "+" or c == "|" then
                if buf == "" then
                    local str = table.remove(words)
                    if isregister(str) or tonumber(str) ~= nil then
                        buf = str .. c
                    else
                        error("Invalid operator '" .. c .. "'")
                    end
                else
                    buf = buf .. c
                end
            elseif c == "@" then
                if buf == "" then
                    local str = table.remove(words)
                    buf = str .."@"
                else
                    buf = buf .. "@"
                end
            else
                buf = buf .. c
            end
        end
    end

    if not(buf == "" or buf == nil or buf == " ") then
        table.insert(words, buf)
    end

    if comment then
        error("Not found end ';'");
    end

    return words
end

local function isrelational(str)
    return str == "xtlo" or str == "xtlonys" or str == "xylo" or str == "xylonys"
        or str == "clo" or str == "niv"
        or str == "llo" or str == "llonys" or str == "xolo" or str == "xolonys"
end

local function ismono(str)
    return str == "xok" or str == "kue" or str == "nll" or str == "l'" or str == "nac"
        or str == "zali" or str == "ycax" or str == "fenx" or str == "cers"
        or str == "dus" or str == "maldus" or str == "lifem" or str == "lifem8" or str == "lifem16"
end

local function skipcount(str)
    if str == "ral" or str == "dosn" or str == "fen" then
        return 0
    elseif ismono(str) then
        return 1
    elseif str == "lar" or str == "fi"
        or str == "lat" or str == "latsna" or str == "inj" then
        return 3
    else
        return 2
    end
end

function analyze(words, options)
    local tokens = {}
    local outlabel = {}
    local inlabel = {}
    local snoj = {}
    local swi = nil
    local skip = 0
    local tmp = nil
    local lifem = {}

    function maybeget(label_or_value)
        for k,v in pairs(snoj) do
            if k == label_or_value then
                return v
            end
        end

        return label_or_value
    end

    -- ラベル処理
    for i, v in ipairs(words) do
        if skip ~= 0 then
            skip = skip - 1
        elseif swi ~= nil then
            local num = tonumber(v, 10)

            if tmp ~= nil and (isregister(v) or string.find(v, "[+|@]") ~= nil or (num ~= nil and num >= 0)) then
                error("invalid label: " .. v)
            elseif swi == "out" then
                outlabel[v] = true
                swi = nil
            elseif swi == "in" then
                inlabel[v] = true
                swi = nil
            else
                if tmp ~= nil then
                    if outlabel[v] ~= nil or inlabel[v] ~= nil then
                        error("duplication label: " .. v)
                    end
                    snoj[v] = tmp
                    tmp = nil
                    swi = nil
                elseif num ~= nil then
                    tmp = v
                else
                    error("invalid value (only number) : " .. v)
                end
            end
        elseif v == "xok" or v == "kue" then
            swi = "out"
        elseif v == "nll" or v == "l'" or v == "cers" then
            swi = "in"
        elseif v == "snoj" then
            swi = "snoj"
        else
            skip = skipcount(v)
            swi = nil
        end
    end

    -- 構文解析
    local i = 1
    local larcheck = 0
    local fsnoj

    if options ~= nil and options.fsnoj ~= nil then
        fsnoj = options.fsnoj
    else
        fsnoj = {}
    end

    while i <= #words do
        local v = words[i]

        if string.sub(v, 1, 1) == "!" then
            if v == "!snoj" then
                fsnoj[words[i + 1]] = true
                i = i + 2
            elseif v == "!fi" then
                if not fsnoj[words[i + 1]] then
                    while i <= #words and v ~= "!if" and v ~= "!ol" do
                        i = i + 1
                        v = words[i]
                    end

                    if i > #words then
                        error("end of file in '!fi'")
                    end

                    i = i + 1
                else
                    i = i + 2
                end
            elseif v == "!fi-niv" then
                if fsnoj[words[i + 1]] then
                    while i <= #words and v ~= "!if" and v ~= "!ol" do
                        i = i + 1
                        v = words[i]
                    end

                    if i > #words then
                        error("end of file in '!fi-niv'")
                    end

                    i = i + 1
                else
                    i = i + 2
                end
            elseif v == "!ol" then
                while i <= #words and v ~= "!if" do
                    i = i + 1
                    v = words[i]
                end

                if i > #words then
                    error("end of file in '!ol'")
                end
            elseif v == "!if" then
                i = i + 1
            end
        elseif ismono(v) then
            if v == "l'" then
                local val, idx = utils.findlist(tokens,function (w) return w.operator ~= "kue" and w.operator ~= "xok" end, true)

                table.insert(tokens, idx, {
                    operator = "nll",
                    operands = {
                        words[i + 1]
                    },
                })
            elseif v == "ycax" or v == "dus" or v == "maldus" then
                table.insert(tokens, {
                    operator = v,
                    operands = {
                        maybeget(words[i + 1])
                    },
                })
            elseif v == "lifem" or v == "lifem8" or v == "lifem16" then
                if tokens[#tokens].operator == "nll" then
                    table.insert(lifem, table.remove(tokens))
                end
                table.insert(lifem,{
                    operator = v,
                    operands = {
                        words[i + 1]
                    },
                })
            else
                table.insert(tokens, {
                    operator = v,
                    operands = {
                        words[i + 1]
                    },
                })
            end
            i = i + 2
        elseif v == "snoj" then
            i = i + 3
        elseif v == "ral" or v == "dosn"  or v == "fen" then
            table.insert(tokens, {
                operator = v,
                operands = {},
            })
            if v == "ral" then
                larcheck = larcheck - 1
            end
            i = i + 1
        elseif v == "lar" or v == "fi" then
            if not isrelational(words[i + 3]) then
                error("'" .. words[i + 3] .. "' is not compare operator")
            end
            table.insert(tokens, {
                operator = v,
                suboperator = words[i + 3],
                operands = {
                    maybeget(words[i + 1]),
                    maybeget(words[i + 2]),
                },
            })
            if v == "lar" then
                larcheck = larcheck + 1
            end
            i = i + 4
        elseif v == "lat" or v == "latsna" or v == "inj" then
            table.insert(tokens, {
                operator = v,
                operands = {
                    maybeget(words[i + 1]),
                    maybeget(words[i + 2]),
                    maybeget(words[i + 3])
                },
            })
            i = i + 4
        elseif v == "'i'c" or v == "'c'i" then
            error("Can't use :" .. v)
        else
            table.insert(tokens, {
                operator = v,
                operands = {
                    maybeget(words[i + 1]),
                    maybeget(words[i + 2])
                },
            })
            i = i + 3
        end
    end

    for i,v in ipairs(lifem) do
        table.insert(tokens, v)
    end

    if larcheck > 0 then
        error("Not found to match 'ral'")
    elseif larcheck < 0 then
        error("Found too many 'ral'")
    end

    return {
        tokens = tokens,
        inlabel = inlabel,
        outlabel = outlabel
    }
end

function getlabel(label, outlabel, inlabel)
    local isaddress = string.match(label, "[@]$")
    if isaddress then
        local labelpart = string.sub(label, 1, string.len(label) - 1)

        if labelpart == "tvarlon-knloan" then
            return "0"
        elseif outlabel[labelpart] == nil then
            if inlabel[labelpart] ~= nil then
                label = "--" .. labelpart .. "--@"
            else
                error("Not found :" .. labelpart)
            end
        end
    else
        if label == "tvarlon-knloan" then
            return "3126834864"
        elseif outlabel[label] == nil then
            if inlabel[label] ~= nil then
                label = "--" .. label .. "--"
            else
                error("Not found :" .. label)
            end
        end
    end
    return label
end

function getvarlabel(var, outlabel, inlabel)
    local first, opd, second = string.match(var, "^(%w+)([+|])(%w+)@$")
    local success, label = pcall(getlabel, var, outlabel, inlabel)

    if first ~= nil and second ~= nil then
        local isfirst = isregister(first)
        local issecond = isregister(second)

        if isfirst and issecond then
            if opd == "|" then
                error("Not supported 'reg|reg'");
            else
                return first .. "+" .. second .. "@"
            end
        elseif isfirst then
            success, label = pcall(getlabel, second, outlabel, inlabel);

            if success then
                return first .. "+" .. label .. "@"
            elseif second == "0" then
                return first .. "@"
            elseif opd == "|" then
                return first .. "+" .. (0x00000000FFFFFFFF & (-tonumber(second))) .. "@"
            else
                return first .. "+" .. tonumber(second) .. "@"
            end
        elseif issecond then
            success, label = pcall(getlabel, first, outlabel, inlabel);

            if success then
                return label .. "+" .. second .. "@"
            elseif opd == "|" then
                error("Not supported 'imm|reg'");
            elseif first == "0" then
                return second .. "@"
            else
                return second .. "+" .. tonumber(first) .. "@"
            end
        else
            error("Not support: " .. first)
        end
    elseif success then
        return label
    elseif var == "xx" then
        error("Not support: xx")
    elseif string.find(var, "[+|]") ~= nil then
        error("Invalid operand: " .. var)
    elseif string.sub(var, string.len(var)) == "@" then
        local varsub = string.match(var, "^(%w+)@$")
        local num = tonumber(varsub, 10)

        if (num ~= nil and num >= 0) then
            return tostring(num) + "@"
        elseif isregister(varsub) then
            return var
        else
            error("Invalid operand: " .. var)
        end
    else
        local num = tonumber(var, 10)
        if (num ~= nil and num >= 0) then
            return tostring(num)
        elseif isregister(var) then
            return var
        else
            error("Invalid operand: " .. var)
        end
    end
end
