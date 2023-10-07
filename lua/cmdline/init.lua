local config = require("cmdline.config")
local util   = require("cmdline.util")
local window = require("cmdline.window")
local binds  = require("cmdline.binds")

local stopListening = function()
    util.stopDebounce()

    vim.schedule(function()
        window.hide()
        util.resetCmdlineCallback()
    end)
end

local updateCmdLine = util.debounce(function()
    if binds.disableUpdate then
        binds.disableUpdate = false
        return true
    end

    local input = vim.fn.getcmdline()
    local completions = vim.fn.getcompletion(input, "cmdline")

    binds.currentCompletions = {}
    binds.currentSelection = -1

    if input:find("'<,'>") then
        input = input:sub(6)
        binds.visualMode = true
    else
        binds.visualMode = false
    end

    if config.opts.window.matchFuzzy then
        completions = util.matchFuzzy(input, completions)
    end

    if vim.tbl_isempty(completions) then
        window.hide()
        return
    end

    local colWidth = util.getColWidth(config.opts.column)
    local columns  = math.floor(tonumber(vim.o.columns, 10) / colWidth)
    local height   = util.getHeight(math.floor(#completions / columns))

    window.refresh(height, config.opts.window.offset)

    completions = util.resizeTable(completions, columns * height)
    completions = util.mapCompletions(completions, colWidth)

    window.clearBuffer(height)

    local i = 1

    for line = 0, height - 1 do
        for column = 0, columns - 1 do
            if i > #completions then
                break
            end

            local endCol = column * colWidth + string.len(completions[i].display)

            if endCol > tonumber(vim.o.columns, 10) then
                break
            end

            vim.api.nvim_buf_set_text(window.buffer, line, column * colWidth, line, endCol, {
                completions[i].display
            })

            if completions[i].isDirectory and config.opts.hl.directory then
                window.hl.default(
                    line, column, colWidth, endCol,
                    config.opts.hl.directory
                )
            else
                window.hl.default(
                    line, column, colWidth, endCol,
                    config.opts.hl.default
                )
            end

            if input ~= "" then
                window.hl.substr(
                    line,
                    column,
                    colWidth,
                    util.currentMatch,
                    completions[i].display,
                    config.opts.hl.substr
                )
            end

            binds.currentCompletions[i] = {
                start  = { line, column * colWidth },
                finish = { line, endCol },
                completion = completions[i].completion
            }

            i = i + 1
        end
    end

    vim.schedule(function()
        vim.cmd([[redraw]])
    end)
end, config.opts.window.debounceMs)

local setup = function(cfg)
    config.user.setOpts(cfg)

    window.init(config.opts.window.offset)

    binds.init(config, window)

    vim.api.nvim_create_autocmd({ "CmdwinEnter" }, {
        callback = function() stopListening() end
    })

    vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
        callback = function()
            if vim.v.event.cmdtype == ':' then
                updateCmdLine()
                util.setCmdlineCallback(updateCmdLine)
            end
        end
    })

    vim.api.nvim_create_autocmd({ "CmdlineLeave" }, {
        callback = function()
            if vim.v.event.cmdtype == ':' then
                stopListening()
            end
        end
    })

    vim.api.nvim_create_autocmd({ "WinLeave" }, {
        callback = function()
            if vim.api.nvim_buf_is_valid(window.buffer) then
                vim.api.nvim_buf_delete(window.buffer, {})
            end
        end
    })

    vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
        callback = function()
            if vim.api.nvim_buf_is_valid(window.buffer) then
                vim.api.nvim_buf_delete(window.buffer, {})
            end
        end
    })
end

return setup
