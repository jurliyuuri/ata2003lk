register = {
    f0 = 0x0,
    f1 = 0x1,
    f2 = 0x2,
    f3 = 0x3,
    f5 = 0x5,
    xx = 0x7,
    ul = 0xf,
}

register.tostring = function(value)
    for k,v in pairs(register) do
        if v == value and type(v) == "number" then
            return k
        end
    end

    return value
end

register.is = function (value)
    for k,v in pairs(register) do
        if v == value then
            return true
        end
    end

    return false
end

operator = {
    ata = 0x00,
    nta = 0x01,
    ada = 0x02,
    ekc = 0x03,
    dto = 0x04,
    dro = 0x05,
    dtosna = 0x06,
    dal = 0x07,
    krz = 0x08,
    malkrz = 0x09,
    krz8i = 0x0a,
    krz16i = 0x0b,
    krz8c = 0x0c,
    krz16c = 0x0d,
    llonys = 0x10,
    xtlonys = 0x11,
    xolonys = 0x12,
    xylonys = 0x13,
    clo = 0x16,
    niv = 0x17,
    llo = 0x18,
    xtlo = 0x19,
    xolo = 0x1a,
    xylo = 0x1b,
    fnx = 0x20,
    mte = 0x21,
    anf = 0x22,
    lat = 0x28,
    latsna = 0x29,
    kak = 0x2b,
    kaksna = 0x2c,
}

operator.tostring = function (value)
    for k,v in pairs(operator) do
        if v == value and type(v) == "number" then
            return k
        end
    end

    return value
end

operator.is = function (value)
    for i,v in ipairs(operator) do
        if v == value then
            return true
        end
    end

    return false
end
