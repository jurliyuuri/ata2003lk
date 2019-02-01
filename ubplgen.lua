require("constant")
require("operand")

-- レジスタ
f0 = reg(register.f0)
f1 = reg(register.f1)
f2 = reg(register.f2)
f3 = reg(register.f3)
f5 = reg(register.f5)
xx = reg(register.xx)
ul = reg(register.ul)

local regtable = {
    f0 = f0,
    f1 = f1,
    f2 = f2,
    f3 = f3,
    f5 = f5,
    xx = xx,
    ul = ul,
}

-- 比較演算子
llonys = operator.llonys
xtlonys = operator.xtlonys
xolonys = operator.xolonys
xylonys = operator.xylonys
clo = operator.clo
niv = operator.niv
llo = operator.llo
xtlo = operator.xtlo
xolo = operator.xolo
xylo = operator.xylo

function iscompare(value)
    return llonys == value or xtlonys == value
        or xolonys == value or xylonys == value
        or clo == value or niv == value
        or llo == value or xtlo == value
        or xolo == value or xylo == value
end

-- ローカル関数

local function tooperand(value)
    local t = type(value)

    if t == "number" then
        return imm32(value)
    elseif t == "string" then
        if regtable[value] ~= nil then
            return regtable[value]
        else
            local num = tonumber(value, 10)
            if num ~= nil then
                return imm32(value)
            else
                return label(value)
            end
        end
    elseif t == "table" and value.isreg ~= nil then
        return value
    else
        error("invalid value: " .. tostring(value) .. ", type : " .. t)
    end
end

local function tomode(opd)
    local isaddress = 0
    if opd.address then
        isaddress = 0x20
    end
    local addxx = 0x10

    if opd:isreg() then
        return 0 | isaddress
    elseif opd:isimm() then
        return 1 | isaddress
    elseif opd:isreg2() then
        return 2 | isaddress
    elseif opd:isregimm() then
        return 3 | isaddress
    elseif opd:islabelreg() then
        return 0 | addxx | isaddress
    elseif opd:islabel() or opd:islabelimm() then
        return 1 | addxx | isaddress
    elseif opd:islabelregimm() then
        return 3 | addxx | isaddress
    else
        error("invalid parameter: " .. opd)
    end
end

local function getmodrm(head, tail)
    local hmod = (tomode(head) << 8)
    if head.reg1 ~= nil then
        hmod = hmod | head.reg1
    end

    local tmod = (tomode(tail) << 8)
    if tail.reg1 ~= nil then
        tmod = tmod | tail.reg1
    end

    return (hmod << 16) | tmod
end

local function packcode(mnemonic, head, tail)
    head = tooperand(head)
    tail = tooperand(tail)

    if iscompare(mnemonic) then
        if tail.label ~= nil then
            if self.labels[tail.label] == nil then
                self.labels[tail.label] = { tail }
            else
                table.insert(self.labels[tail.label], tail)
            end
        end    
    else
        if (not tail.address) and (tail:isreg2() or tail:isimm() or tail:isregimm() or tail:islabel()) then
            error("invalid value: " .. tail)
        end
    end

    return {
        mnemonic = mnemonic,
        modrm = getmodrm(head, tail),
        head = head,
        tail = tail,
    }
end

-- ジェネレータ本体
function ubpl ()
    local generator = {
        codes = {},
        labeladrs = {},
    }

    generator.nll = function(self, head)
        head = tooperand(head)
        if not head:islabel() then
            error("invalid value: " .. head)
        end

        self.labeladrs[head.label] = #self.codes
        return self
    end

    generator.l = function(self, head)
        if #self.codes == 0 then
            error("not found operator before l'")
        end

        head = tooperand(head)
        if not head:islabel() then
            error("invalid value: " .. head)
        end

        self.labeladrs[head.label] = #self.codes - 1
        return self
    end

    generator.ata = function(self, head, tail)
        table.insert(self.codes, packcode(operator.ata, head, tail))
        return self
    end

    generator.nta = function(self, head, tail)
        table.insert(self.codes, packcode(operator.nta, head, tail))
        return self
    end

    generator.ada = function(self, head, tail)
        table.insert(self.codes, packcode(operator.ada, head, tail))
        return self
    end

    generator.ekc = function(self, head, tail)
        table.insert(self.codes, packcode(operator.ekc, head, tail))
        return self
    end

    generator.dto = function(self, head, tail)
        table.insert(self.codes, packcode(operator.dto, head, tail))
        return self
    end

    generator.dro = function(self, head, tail)
        table.insert(self.codes, packcode(operator.dro, head, tail))
        return self
    end

    generator.dtosna = function(self, head, tail)
        table.insert(self.codes, packcode(operator.dtosna, head, tail))
        return self
    end

    generator.dal = function(self, head, tail)
        table.insert(self.codes, packcode(operator.dal, head, tail))
        return self
    end

    generator.krz = function(self, head, tail)
        table.insert(self.codes, packcode(operator.krz, head, tail))
        return self
    end

    generator.malkrz = function(self, head, tail)
        table.insert(self.codes, packcode(operator.malkrz, head, tail))
        return self
    end

    generator.krz8i = function(self, head, tail)
        table.insert(self.codes, packcode(operator.krz8i, head, tail))
        return self
    end

    generator.krz16i = function(self, head, tail)
        table.insert(self.codes, packcode(operator.krz16i, head, tail))
        return self
    end

    generator.krz8c = function(self, head, tail)
        table.insert(self.codes, packcode(operator.krz8c, head, tail))
        return self
    end

    generator.krz16c = function(self, head, tail)
        table.insert(self.codes, packcode(operator.krz16c, head, tail))
        return self
    end

    generator.fi = function(self, head, tail, opd)
        if iscompare(opd) then
            table.insert(self.codes, packcode(opd, head, tail))
            return self
        else
            error("invalid value: " .. operator.tostring(opd))
        end
    end

    generator.fnx = function(self, head, tail)
        table.insert(self.codes, packcode(operator.fnx, head, tail))
        return self
    end

    generator.mte = function(self, head, tail)
        table.insert(self.codes, packcode(operator.mte, head, tail))
        return self
    end

    generator.anf = function(self, head, tail)
        table.insert(self.codes, packcode(operator.anf, head, tail))
        return self
    end

    generator.lat = function(self, head, tail)
        table.insert(self.codes, packcode(operator.lat, head, tail))
        return self
    end

    generator.latsna = function(self, head, tail)
        table.insert(self.codes, packcode(operator.latsna, head, tail))
        return self
    end

    generator.tobinary = function (self)
        local binary = {}

        for i,v in ipairs(self.codes) do
            local b1, b2, b3, b4 = (v.mnemonic >> 24) & 0xff, (v.mnemonic >> 16) & 0xff, (v.mnemonic >> 8) & 0xff, v.mnemonic & 0xff
            table.insert(binary, b1)
            table.insert(binary, b2)
            table.insert(binary, b3)
            table.insert(binary, b4)

            b1, b2, b3, b4 = (v.modrm >> 24) & 0xff, (v.modrm >> 16) & 0xff, (v.modrm >> 8) & 0xff, v.modrm & 0xff
            table.insert(binary, b1)
            table.insert(binary, b2)
            table.insert(binary, b3)
            table.insert(binary, b4)

            local opd = v.head.imm
            if opd == nil then opd = 0 end
            if v.head.label ~= nil then
                opd = opd + (self.labeladrs[v.head.label] - i) * 16
                opd = opd & 0xffffffff
            end

            b1, b2, b3, b4 = (opd >> 24) & 0xff, (opd >> 16) & 0xff, (opd >> 8) & 0xff, opd & 0xff
            table.insert(binary, b1)
            table.insert(binary, b2)
            table.insert(binary, b3)
            table.insert(binary, b4)

            opd = v.tail.imm
            if opd == nil then opd = 0 end
            if v.tail.label ~= nil then
                opd = opd + (self.labeladrs[v.tail.label] - i) * 16
                opd = opd & 0xffffffff
            end

            b1, b2, b3, b4 = (opd >> 24) & 0xff, (opd >> 16) & 0xff, (opd >> 8) & 0xff, opd & 0xff
            table.insert(binary, b1)
            table.insert(binary, b2)
            table.insert(binary, b3)
            table.insert(binary, b4)
        end

        return binary
    end

    return generator
end
