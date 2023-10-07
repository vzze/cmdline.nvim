local util = {}

util.timeout = nil

util.stopDebounce = function()
    if util.timeout then
        util.timeout:stop()
        util.timeout:close()
        util.timeout = nil
    end
end

util.debounce = function(callback, delay)
    return function(...)
        local args = ...

        util.stopDebounce()

        util.timeout = vim.loop.new_timer()

        util.timeout:start(delay, 0, function()
            vim.schedule(function()
                callback(args)
            end)

            util.stopDebounce()
        end)
    end
end

util.getColWidth = function(column)
    local colWidth

    for i = 1, column.maxNumber do
        local testWidth = math.floor(
            tonumber(vim.o.columns, 10) / i
        )

        if testWidth <= column.minWidth then
            return column.minWidth
        else
            colWidth = testWidth
        end
    end

    return colWidth
end

util.cmdlineCallback = nil

util.setCmdlineCallback = function(cb)
    util.cmdlineCallback = vim.api.nvim_create_autocmd(
        { 'CmdlineChanged' },
        {
            callback = cb
        }
    )
end

util.resetCmdlineCallback = function()
    if util.cmdlineCallback then
        vim.api.nvim_del_autocmd(util.cmdlineCallback)
        util.cmdlineCallback = nil
    end
end

util.currentMatch = nil

util.matchFuzzy = function(input, completions)
    if input == "" then
        return completions
    end

    local split = vim.split(input, ' ')
    local match = split[#split]

    util.currentMatch = match

    if match:len() < 1 then
        return completions
    end

    match = string.gsub(match, "/", { ["/"] = "\\" })

    return vim.fn.matchfuzzy(completions, match)
end

util.getHeight = function(possibleHeight)
    local maxHeight = math.floor(vim.o.lines * 0.3)

    if possibleHeight < maxHeight then
        if possibleHeight == 0 then
            return 1
        else
            return possibleHeight
        end
    else
        return maxHeight
    end
end

util.resizeTable = function(table, newSize)
    local newTable = {}

    for i = 1, #table do
        newTable[i] = table[i]

        if i > newSize then
            break
        end
    end

    return newTable
end

util.mapCompletions = function(completions, colWidth)
    return vim.tbl_map(function(el)
        local isDirectory = vim.fn.isdirectory(vim.fn.fnamemodify(el, ":p")) == 1
        local mod = vim.fn.fnamemodify(el, ":p:t")

        local disp

        if mod == "" then
            disp = vim.fn.fnamemodify(el, ":p:h:t")
        else
            disp = mod
        end

        if string.len(disp) >= colWidth then
            disp = string.sub(disp, 1, colWidth - 5) .. "..."
        end

        return {
            display = disp,
            completion = el,
            isDirectory = isDirectory
        }
    end, completions)
end

return util
