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

local wordlist = readfile(arg[1])

for i,v in ipairs(wordlist) do
    print(i,v)
end