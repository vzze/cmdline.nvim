local window = {}

window.buffer = nil
window.id     = nil

window.currentHeight = 0

window.hide = function()
    if vim.api.nvim_win_is_valid(window.id) then
        vim.api.nvim_win_hide(window.id)
    end

    window.currentHeight = 0
end

window.config = function(height, offset)
    return {
        relative = "editor",
        border = nil,
        style = 'minimal',
        width = vim.o.columns,
        height = height,
        row = vim.o.lines - height - offset,
        col = 0
    }
end

window.init = function(offset)
    window.buffer = vim.api.nvim_create_buf(false, true)

    window.id = vim.api.nvim_open_win(
        window.buffer, false, window.config(1, offset)
    )

    window.hide()
end

window.refresh = function(height, offset)
    if window.currentHeight == height then
        return
    end

    window.currentHeight = height

    if not vim.api.nvim_buf_is_valid(window.buffer) then
        window.buffer = vim.api.nvim_create_buf(false, true)
    end

    if not vim.api.nvim_win_is_valid(window.id) then
        window.id = vim.api.nvim_open_win(
            window.buffer, false, window.config(height, offset)
        )
    else
        vim.api.nvim_win_set_config(
            window.id, window.config(height, offset)
        )
    end
end

window.clearBuffer = function(height)
    local tbl = {}

    for _ = 1, height do
        tbl[#tbl + 1] = (" "):rep(vim.o.columns)
    end

    vim.api.nvim_buf_set_lines(
        window.buffer,
        0,
        height,
        false,
        tbl
    )
end

window.ns = {
    directory = vim.api.nvim_create_namespace('__ccs_hls_namespace_directory___'),
    search    = vim.api.nvim_create_namespace('__ccs_hls_namespace_search___'),
    substr    = vim.api.nvim_create_namespace('__ccs_hls_namespace_substr___')
}

window.hl = {
    default = function(line, col, colWidth, endCol, defaultHl)
        vim.highlight.range(
            window.buffer,
            window.ns.directory,
            defaultHl,
            { line, col * colWidth},
            { line, endCol },
            { priority = 150 }
        )
    end,
    substr = function(line, col, colWidth, match, txt, substrHl)
        if match:len() < 1 or substrHl == nil then
            return
        end

        local x, y = string.find(txt, match, 1, true)

        if x == nil or y == nil then
            return
        end

        vim.highlight.range(
            window.buffer,
            window.ns.substr,
            substrHl,
            { line, col * colWidth + x - 1 },
            { line, col * colWidth + y },
            { priority = 150 }
        )
    end,
    search = function(start, finish, selectionHl)
        if selectionHl == nil then
            return
        end

        vim.highlight.range(
            window.buffer,
            window.ns.search,
            selectionHl,
            start,
            finish,
            { priority = 200 }
        )
    end
}

return window
