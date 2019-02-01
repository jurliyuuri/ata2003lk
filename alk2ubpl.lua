require("ata2003lk")
require("ubplgen")

local filename = nil
local options = {
    fsnoj = {},
}

local i = 1
while i <= #arg do
    v = arg[i]
    if v == "--el" then
        i = i + 1
        options.fsnoj[arg[i]] = true
    else
        filename = arg[i]
    end
    i = i + 1
end

local wordlist = readfile(filename)
local analyzelist = analyze(wordlist, options)

local function isregister(str)
    return str == "f0" or str == "f1" or str == "f2"
        or str == "f3" or str == "f5"
end

local function tooperand(operand, outlabel, inlabel)
    local isaddress = string.sub(operand, -1) == "@"
    local opd = operand

    if isaddress then
        opd = string.sub(opd, 1, #opd - 1)
    end

    local first, opr, second = string.match(opd, "^(%w+)([+|])(%w+)$")
    local success, tlabel = pcall(getlabel, opd, outlabel, inlabel)
    
    if first ~= nil and second ~= nil then
        local success, tlabel = pcall(getlabel, first, outlabel, inlabel)

        if success then
            first = label(first)
        elseif string.sub(first, 1, 1) == "f" then
            first = reg(first)
        else
            first = imm32(first)
        end
        
        success, tlabel = pcall(getlabel, second, outlabel, inlabel)

        if success then
            if opr == "|" then
                error("Invalid operand :" .. operand)
            end
            second = label(second)
        elseif string.sub(second, 1, 1) == "f" then
            if opr == "|" then
                error("Invalid operand :" .. operand)
            end
            second = reg(second)
        else
            second = imm32(second)
        end

        if isaddress then
            return seti(first + second)
        else
            error("Invalid operand :" .. operand)
        end
    elseif success then
        local tmp = label(tlabel)
        if isaddress then
            tmp = seti(tmp)
        end

        return tmp
    else
        local num = tonumber(opd, 10)

        if (num ~= nil and num >= 0) then
            local tmp = imm32(num)
            if isaddress then
                tmp = seti(tmp)
            end
            
            return tmp
        elseif isregister(opd) then
            local tmp = reg(opd)
            if isaddress then
                tmp = seti(tmp)
            end
            
            return tmp
        else
            error("Invalid operand: " .. operand)
        end
    end
end

local function tocompare(suboperator)
    return operator[suboperator]
end

function transpile(analyzed)
    local generator = ubpl()
    local i = 1
    local tokens = analyzed.tokens
    local count = #tokens
    local larlabel = {}
    local larsitlabel = {}

    while i <= count do
        local token = tokens[i]

        if token.operator == "zali" then
            local opd = tooperand(token.operands[1], analyzed.outlabel, analyzed.inlabel)

            generator:nta(4, f5)
                :krz(opd, seti(f5))
        elseif token.operator == "ycax" then
            local opd = tooperand(token.operands[1], analyzed.outlabel, analyzed.inlabel)

            if opd:isimm() then
                generator:ata(opd.imm * 4, f5)
            else
                for i=1,4 do
                    generator:ata(opd, f5)
                end
            end
        elseif token.operator == "fenx" then
            local tlabel = getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel)

            generator:nta(4, f5)
                :fnx(tlabel, seti(f5))
                :ata(4, f5)
        elseif token.operator == "cers" then
            local tlabel = getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel)
            
            generator:nll(tlabel, seti(f5))
        elseif token.operator == "dosn" then
            generator:krz(seti(f5), xx)
        elseif token.operator == "dus" then
            local opd = tooperand(token.operands[1], analyzed.outlabel, analyzed.inlabel)

            generator:krz(opd, xx)
        elseif token.operator == "maldus" then
            local opd = tooperand(token.operands[1], analyzed.outlabel, analyzed.inlabel)

            generator:malkrz(opd, xx)
        elseif token.operator == "lar" then
            table.insert(larlabel, "--lar@".. i)
            table.insert(larsitlabel, "--lar--sit--" .. i)
            
            local opd1 = tooperand(token.operands[1], analyzed.outlabel, analyzed.inlabel)
            local opd2 = tooperand(token.operands[2], analyzed.outlabel, analyzed.inlabel)

            generator:nll(larlabel[#larlabel])
                :fi(opd1, opd2, tocompare(token.suboperator))
                :malkrz(larsitlabel[#larsitlabel], xx)
        elseif token.operator == "ral" then
            generator:krz(table.remove(larlabel), xx)
                :nll(table.remove(larsitlabel))
            
            if i == count then
                generator:krz(f0, f0)
            end
        elseif token.operator == "nll" then
            local tlabel = getlabel(token.operands[1], analyzed.outlabel, analyzed.inlabel)

            generator:nll(tlabel)
        elseif token.operator == "fi" then
            local opd1 = tooperand(token.operands[1], analyzed.outlabel, analyzed.inlabel)
            local opd2 = tooperand(token.operands[2], analyzed.outlabel, analyzed.inlabel)

            generator:fi(opd1, opd2, tocompare(token.suboperator))
        else
            local operands = {}
            for i, v in ipairs(token.operands) do
                table.insert(operands, tooperand(v, analyzed.outlabel, analyzed.inlabel))
            end

            generator[token.operator](generator, operands[1], operands[2], operands[3])
        end

        i = i + 1
    end

    local outfile, err = io.open(string.match(filename, "(.+)%.alk") .. ".ubpl", "wb")
    if outfile == nil then
        print("error (outfile): " .. tostring(err))
        os.exit(1)
    end

    for i, v in ipairs(generator:tobinary()) do
        outfile:write(string.char(v))
    end
end

transpile(analyzelist)
