utils = {}

function utils.findlist(list, predict, last)
    if type(list) ~= "table" then
        error("bad argument #1 to findlist")
    end
    if type(predict) ~= "function" then
        error("bad argument #2 to findlist")
    end
    if last == nil then
        last = false
    end

    local f, t, s;

    if last then
        f = #list
        t = 1
        s = -1
    else
        f = 1
        t = #list
        s = 1
    end

    for i=f,t,s do
        local v = list[i]
        if predict(v, i) then
            return v, i
        end
    end

    return nil, nil
end
