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
                if buf ~= "" then
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

                    if str == "q" then
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

    return words
end

local function isregister(str)
    return str == "f0" or str == "f1" or str == "f2" or str == "f3"
end

local function isrelational(str)
    return str == "xtlo" or str == "xtlonys" or str == "xylo" or str == "xylonys"
        or str == "clo" or str == "niv"
        or str == "llo" or str == "llonys" or str == "xolo" or str == "xolonys"
end

function analyze(words)
    local tokens = {}
    local outlabel = {}
    local inlabel = {}
    local swi = nil

    -- ラベル処理
    for i, v in ipairs(words) do
        if swi ~= nil then
            if isregister(v) then
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
            swi = nil
        end
    end

    -- 構文解析
    local i = 1
    local larcheck = 0
    while i <= #words do
        local v = words[i]

        if v == "xok" or v == "kue" or v == "nll" or v == "l'" or v == "nac"
            or v == "zali" or v == "ycax" or v == "fenx" or v == "cers" then
            table.insert(tokens, {
                operator = v,
                operands = {
                    words[i + 1]
                },
            })
            i = i + 2
        elseif v == "ral" or v == "dosn" then
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
        elseif v == "lat" or v == "latsna" then
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

    return {
        tokens = tokens,
        inlabel = inlabel,
        outlabel = outlabel,
    }
end

local function getlabel(label, outlabel, inlabel)
    if outlabel[label] == nil then
        if inlabel[label] ~= nil then
            label = "--" .. label .. "--"
        else
            error("Not found :" .. label)
        end
    end

    return label
end

local function getvarlabel(var, outlabel, inlabel)
    local count = string.match(var, "q@(%d+)")
    local success, label = pcall(getlabel, var, outlabel, inlabel)

    if count ~= nil then
        return "f5+" .. ((tonumber(count) + 1) * 4) .. "@"
    elseif success then
        return label
    else
        return var
    end
end

function create(analyzed)
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
                taleb.insert(result, {
                    operator = "ata",
                    operands = {
                        token.operands[1],
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
        elseif token.operator == "lar" then
            table.insert(larlabel, "--lar--".. i .."--")
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
            table.insert(larsitlabel, "--lar--sit--" .. i .. "--")
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

    return result
end

local wordlist = readfile(arg[1])
local analyzelist = analyze(wordlist)
local resultlist = create(analyzelist)

local outfile, err = io.open(string.match(arg[1], "(.+)%.alk") .. ".lk", "w")
if outfile == nil then
    print("error (outfile): " .. tostring(err))
    os.exit(1)
end

outfile:write("'i'c\n")
for i, v in ipairs(resultlist) do
    if v.suboperator ~= nil then
        outfile:write(v.operator .. " " .. table.concat(v.operands, " ") .. " " .. v.suboperator .. "\n")
    else
        outfile:write(v.operator .. " " .. table.concat(v.operands, " ") .. "\n")
    end
end
