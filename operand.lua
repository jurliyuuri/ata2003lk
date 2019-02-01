require("constant")

local function create(reg1, reg2, imm, label, address)
    local operand = {
        reg1 = reg1,
        reg2 = reg2,
        imm = imm,
        label = label,
        address = address,
    }

    operand.isreg = function (self)
        return self.reg1 ~= nil and self.reg2 == nil
            and self.imm == nil and self.label == nil
    end

    operand.isimm = function (self)
        return self.reg1 == nil and self.reg2 == nil
            and self.imm ~= nil and self.label == nil
    end

    operand.isreg2 = function (self)
        return self.reg1 ~= nil and self.reg2 ~= nil
            and self.imm == nil and self.label == nil
    end

    operand.isregimm = function (self)
        return self.reg1 ~= nil and self.reg2 == nil
            and self.imm ~= nil and self.label == nil
    end

    operand.islabel = function (self)
        return self.reg1 == nil and self.reg2 == nil
            and self.imm == nil and self.label ~= nil
    end

    operand.islabelreg = function (self)
        return self.reg1 ~= nil and self.reg2 == nil
            and self.imm == nil and self.label ~= nil
    end

    operand.islabelimm = function (self)
        return self.reg1 == nil and self.reg2 == nil
            and self.imm ~= nil and self.label ~= nil
    end

    operand.islabelregimm = function (self)
        return self.reg1 ~= nil and self.reg2 == nil
            and self.imm ~= nil and self.label ~= nil
    end

    setmetatable(operand, {
        __add = function (self, other)
            if type(other) == "number" then
                other = create(nil, nil, other, nil, false)
            elseif type(other) == "string" then
                other = create(nil, nil, nil, other, false)
            end
            if self.address or other.address then
                error("not supported : 'a@ + b@'")
            end

            local s_flag = {
                isreg = self.reg1 ~= nil,
                isreg2 = self.reg2 ~= nil,
                islabel = self.label ~= nil,
            }

            local o_flag = {
                isreg = other.reg1 ~= nil,
                isreg2 = other.reg2 ~= nil,
                islabel = other.label ~= nil,
            }

            if ((s_flag.isreg or s_flag.islabel) and o_flag.isreg2)
                or (s_flag.isreg2 and (o_flag.isreg or o_flag.islabel)) then
                    error("not supported : 'reg1 + reg2 + reg3/label'")
            end

            if (s_flag.isreg and s_flag.islabel and o_flag.isreg)
                or (s_flag.isreg and o_flag.isreg or o_flag.islabel) then
                    error("not supported : 'reg1 + reg2 + reg3/label'")
            end

            if s_flag.islabel and o_flag.islabel then
                error("not supported : 'label + label'")
            end

            local result = create()
            result.imm = 0

            if self.imm ~= nil then result.imm = result.imm + self.imm end
            if other.imm ~= nil then result.imm = result.imm + other.imm end
            if result.imm == 0 then result.imm = nil end

            if s_flag.islabel then result.label = self.label
            elseif o_flag.label ~= nil then result.label = other.label end
           
            if s_flag.isreg then result.reg1 = self.reg1
            elseif o_flag.isreg then result.reg1 = other.reg1 end

            if s_flag.isreg then result.reg2 = other.reg1
            else result.reg2 = nil end

            return result
        end,
        __tostring = function (self)
            local list = {}

            if self.reg1 ~= nil then
                table.insert(list, register.tostring(self.reg1))
            end

            if self.reg2 ~= nil then
                table.insert(list, register.tostring(self.reg2))
            end

            if self.imm ~= nil then
                table.insert(list, self.imm)
            end

            if self.label ~= nil then
                table.insert(list, self.label)
            end

            local str = table.concat(list, "+")

            if self.address then
                return str .. "@"
            else
                return str
            end
        end,
        __concat = function (self, value)
            return tostring(self) .. tostring(value)
        end,
    })

    return operand
end

function imm32(num)
    num = tonumber(num)

    if type(num) == "number" then
        return create(nil, nil, num, nil, nil)
    else
        error("imm32 type is only 'number'")
    end
end

function label(str)
    local num = tonumber(str)

    if num ~= nil or register[str] ~= nil then
        error("invaild label's name :" .. str)
    elseif type(str) == "string" then
        return create(nil, nil, nil, str, nil)
    else
        error("label type is only 'string'")
    end
end

function seti(opd)
    local opdtype = type(opd)
    if opdtype == "string" then
        local num = tonumber(opd)

        if num ~= nil then
            return create(nil, nil, num, nil, true)
        elseif register[opd] ~= nil then
            return create(register[opd], nil, nil, nil, true)
        else
            return create(nil, nil, nil, opd.label, true)
        end
    elseif opdtype == "number" then
        return create(nil, nil, opd, nil, true)
    else
        return create(opd.reg1, opd.reg2, opd.imm, opd.label, true)
    end
end

function reg(val)
    if register.is(tonumber(val)) then
        return create(tonumber(val), nil, nil, nil, false)
    elseif register[val] ~= nil then
        return create(register[val], nil, nil, nil, false)
    else
        error("invaild register's value: " .. val .. " : " .. type(val))
    end
end
