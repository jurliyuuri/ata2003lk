
local function isregister(str)
    return str == "f0" or str == "f1" or str == "f2"
        or str == "f3" or str == "f5" or str == "q"
end

function readfile(filename)
    local words = {}
    local infile
    local err

    infile, err = io.open(filename, "r")
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
                if buf ~= "" and string.sub(buf, string.len(buf)) ~= "@" then
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
                if string.sub(buf, string.len(buf)) == "@" then
                    -- 何もしない
                elseif buf ~= "" then
                    table.insert(words, buf)
                    buf = ""
                end
            elseif c == "@" then
                if buf == "" then
                    local str = table.remove(words)

                    if isregister(str) then
                        buf = str .."@"
                    else
                        error("Invalid pattern: '@'")
                    end
                else
                    buf = buf .. "@"
                end
            else
                buf = buf .. c
            end
        end
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
        or str == "dus" or str == "maldus"
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

function analyze(words)
    local tokens = {}
    local outlabel = {}
    local inlabel = {}
    local swi = nil
    local skip = 0

    -- ラベル処理
    for i, v in ipairs(words) do
        if skip ~= 0 then
            skip = skip - 1
        elseif swi ~= nil then
            local num = tonumber(v, 10)
            if isregister(v) or string.find(v, "@", 1, true) ~= nil or (num ~= nil and num >= 0) then
                error("invalid label: " .. v)
            elseif swi == "out" then
                outlabel[v] = true
            else
                inlabel[v] = true
            end
            swi = nil
        elseif v == "xok" or v == "kue" then
            swi = "out"
        elseif v == "nll" or v == "l'" or v == "cers" then
            swi = "in"
        else
            skip = skipcount(v)
            swi = nil
        end
    end

    -- 構文解析
    local i = 1
    local larcheck = 0
    while i <= #words do
        local v = words[i]

        if ismono(v) then
            table.insert(tokens, {
                operator = v,
                operands = {
                    words[i + 1]
                },
            })
            i = i + 2
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
                    words[i + 1],
                    words[i + 2],
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
                    words[i + 1],
                    words[i + 2],
                    words[i + 3]
                },
            })
            i = i + 4
        elseif v == "'i'c" or v == "'c'i" then
            error("Can't use :" .. v)
        else
            table.insert(tokens, {
                operator = v,
                operands = {
                    words[i + 1],
                    words[i + 2]
                },
            })
            i = i + 3
        end
    end

    if larcheck > 0 then
        error("Not found to match 'ral'")
    elseif larcheck < 0 then
        error("Found too many 'ral'")
    end

    return {
        tokens = tokens,
        inlabel = inlabel,
        outlabel = outlabel,
    }
end

local function getlabel(label, outlabel, inlabel)
    if label == "tvarlon-knloan" then
        return "3126834864"
    elseif outlabel[label] == nil then
        if inlabel[label] ~= nil then
            label = "--" .. label .. "--"
        else
            error("Not found :" .. label)
        end
    end

    return label
end

local function getvarlabel(var, outlabel, inlabel)
    local first, second = string.match(var, "^(%w+)@(%d+)$")
    local success, label = pcall(getlabel, var, outlabel, inlabel)

    if first ~= nil and second ~= nil then
        if first == "q" then
            return "f5+" .. ((tonumber(second) + 1) * 4) .. "@"
        elseif isregister(first) then
            if second == "0" then
                return first .. "@"
            else
                return first .. "+" .. (tonumber(second) * 4) .. "@"
            end
        else
            error("Not support: " .. first)
        end
    elseif success then
        return label
    elseif var == "xx" then
        error("Not support: xx")
    elseif string.find(var, "@", 1, true) ~= nil then
        error("Invalid operand: " .. var)
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

function transpile(analyzed)
    local i = 1
    local tokens = analyzed.tokens
    local count = #tokens
    local result = {}
    local larlabel = {}
    local larsitlabel = {}

    while i <= count do
        local token = tokens[i]

        if token.operator == "zali" then
            table.insert(result, {
                operator = "nta",
                operands = { "4", "f5" },
            })
            table.insert(result, {
                operator = "krz",
                operands = {
                    getvarlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel),
                    "f5@",
                },
            })
        elseif token.operator == "ycax" then
            local num = tonumber(token.operands[1])

            if num ~= nil then
                table.insert(result, {
                    operator = "ata",
                    operands = {
                        num * 4,
                        "f5",
                    },
                })
            else
                table.insert(result, {
                    operator = "dro",
                    operands = {
                        "2",
                        getvarlabel(token.operands[1]),
                    },
                })
                table.insert(result, {
                    operator = "ata",
                    operands = {
                        getvarlabel(token.operands[1]),
                        "f5",
                    },
                })
            end
        elseif token.operator == "fenx" then
            table.insert(result, {
                operator = "nta",
                operands = { "4", "f5" },
            })
            table.insert(result, {
                operator = "inj",
                operands = {
                    getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel),
                    "xx",
                    "f5@"
                },
            })
            table.insert(result, {
                operator = "ata",
                operands = { "4", "f5" },
            })
        elseif token.operator == "cers" then
            table.insert(result, {
                operator = "nll",
                operands = {
                    getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel)
                },
            })
        elseif token.operator == "dosn" then
            table.insert(result, {
                operator = "krz",
                operands = { "f5@", "xx" }
            })
        elseif token.operator == "dus" then
            table.insert(result, {
                operator = "krz",
                operands = {
                    getvarlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel),
                    "xx",
                }
            })
        elseif token.operator == "maldus" then
            table.insert(result, {
                operator = "malkrz",
                operands = {
                    getvarlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel),
                    "xx",
                }
            })
        elseif token.operator == "lar" then
            table.insert(larlabel, "--lar--".. i)
            table.insert(result, {
                operator = "nll",
                operands = { larlabel[#larlabel] },
            })
            table.insert(result, {
                operator = "fi",
                suboperator = token.suboperator,
                operands = {
                    getvarlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel),
                    getvarlabel(token.operands[2], analyzed.outlabel, analyzed.inlabel),
                }
            })
            table.insert(larsitlabel, "--lar--sit--" .. i)
            table.insert(result, {
                operator = "malkrz",
                operands = { larsitlabel[#larlabel], "xx" },
            })
        elseif token.operator == "ral" then
            table.insert(result, {
                operator = "krz",
                operands = { table.remove(larlabel), "xx" }
            })
            table.insert(result, {
                operator = "nll",
                operands = { table.remove(larsitlabel) }
            })
            if i == count then
                table.insert(result, {
                    operator = "fen",
                    operands = {},
                })
            end
        elseif token.operator == "nll" then
            table.insert(result, {
                operator = "nll",
                operands = {
                    getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel)
                },
            })
        elseif token.operator == "l'" then
            table.insert(result, {
                operator = "l'",
                operands = {
                    getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel)
                },
            })
        elseif token.operator == "fi" then
            table.insert(result, {
                operator = "fi",
                suboperator = token.suboperator,
                operands = {
                    getvarlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel),
                    getvarlabel(token.operands[2], analyzed.outlabel, analyzed.inlabel),
                },
            })
        else
            local operands = {}
            for i, v in ipairs(token.operands) do
                table.insert(operands, getvarlabel(v, analyzed.outlabel, analyzed.inlabel))
            end

            table.insert(result, {
                operator = token.operator,
                operands = operands,
            })
        end

        i = i + 1
    end

    local outfile, err = io.open(string.match(arg[1], "(.+)%.alk") .. ".lk", "w")
    if outfile == nil then
        print("error (outfile): " .. tostring(err))
        os.exit(1)
    end

    outfile:write("'i'c\n")
    for i, v in ipairs(result) do
        if v.suboperator ~= nil then
            outfile:write(v.operator .. " " .. table.concat(v.operands, " ") .. " " .. v.suboperator .. "\n")
        else
            outfile:write(v.operator .. " " .. table.concat(v.operands, " ") .. "\n")
        end
    end
end

local wordlist = readfile(arg[1])
local analyzelist = analyze(wordlist)
-- -- 確認用
-- print(analyzelist)
-- for i, v in ipairs(analyzelist.tokens) do
--     if v.suboperator ~= nil then
--         print(i, v.operator .. " " .. table.concat(v.operands, " ") .. " " .. v.suboperator)
--     else
--         print(i, v.operator .. " " .. table.concat(v.operands, " "))
--     end
-- end

transpile(analyzelist)
