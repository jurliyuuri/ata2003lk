require("ata2003lk")

local wordlist = readfile(arg[1])
local analyzelist = analyze(wordlist)
-- 確認用
-- print(analyzelist)
-- for i, v in ipairs(analyzelist.tokens) do
--     if v.suboperator ~= nil then
--         print(i, v.operator .. " " .. table.concat(v.operands, " ") .. " " .. v.suboperator)
--     else
--         print(i, v.operator .. " " .. table.concat(v.operands, " "))
--     end
-- end

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
                    operator = "ata",
                    operands = {
                        getvarlabel(token.operands[1]),
                        "f5",
                    },
                })
                table.insert(result, {
                    operator = "ata",
                    operands = {
                        getvarlabel(token.operands[1]),
                        "f5",
                    },
                })
                table.insert(result, {
                    operator = "ata",
                    operands = {
                        getvarlabel(token.operands[1]),
                        "f5",
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

transpile(analyzelist)