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
                if buf ~= "" then
                    table.insert(words, buf)
                    buf = ""
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
        or str == "f4" or str == "f5" or str == "f6" or str == "xx"
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
        elseif v == "nll" or v == "l'" then
            swi = "in"
        else
            swi = nil
        end
    end

    -- 構文解析
    local i = 1
    while i <= #words do
        local v = words[i]

        if v == "xok" or v == "kue" or v == "nll" or v == "l'" or v == "nac"
            or v == "zali" or v == "fenx" or v == "cers" then
            table.insert(tokens, {
                operator = v,
                operands = {
                    words[i + 1]
                },
            })
            i = i + 2
        elseif v == "ral" or v == "dosn" or v == "ycax" then
            table.insert(tokens, {
                operator = v,
                operands = {},
            })
            i = i + 1
        elseif v == "lar" or v == "fi" then
            table.insert(tokens, {
                operator = words[i + 3],
                operands = {
                    words[i + 1],
                    words[i + 2],
                },
            })
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

    return tokens
end

function create(tokens)
    return tokens
end

local wordlist = readfile(arg[1])
local tokenlist = analyze(wordlist)
local resultlist = create(tokenlist)

print("")
for i, v in ipairs(wordlist) do
    print(i, v)
end

print("")
for i, v in ipairs(tokenlist) do
    print(i, v.operator .. " [" .. table.concat(v.operands, ", ") .. "]")
end

