local opts = {}

opts.match_fuzzy = true
opts.highlight_selection = true
opts.selection_hl = "Search"
opts.highlight_directories = true
opts.directory_hl = "Directory"
opts.max_col_num = 6
opts.min_col_width = 20
opts.debounce_ms = 10
opts.offset = 1

local util = {}

util.cmdline_changed = nil

util.col_width = function()
    local col_width

    for i = 1, opts.max_col_num do
        local test_width = math.floor(tonumber(vim.o.columns, 10) / i)
        if test_width <= opts.min_col_width then
            return col_width
        else
            col_width = test_width
        end
    end

    return col_width
end

util.del_autocmd = function()
    if util.cmdline_changed ~= nil then
        vim.api.nvim_del_autocmd(util.cmdline_changed)
        util.cmdline_changed = nil
    end
end

util.timeout = nil

util.debounce = function(callback, delay)
    return function(...)
        local args = ...

        if util.timeout then
            util.timeout:stop()
            util.timeout:close()
            util.timeout = nil
        end

        util.timeout = vim.loop.new_timer()
        util.timeout:start(delay, 0, function()
            vim.schedule(function()
                callback(args)
            end)
            util.timeout:stop()
            util.timeout:close()
            util.timeout = nil
        end)
    end
end

util.dir_hl = vim.api.nvim_create_namespace('__ccs_hls_namespace_directory___')
util.search_hl = vim.api.nvim_create_namespace('__ccs_hls_namespace_search___')
util.current_selection = nil
util.current_completions = nil
util.disable_cmdline_change = false

local window = {}

window.buffer = nil
window.wh = nil

window.hide = function()
    if vim.api.nvim_win_is_valid(window.wh) then
        vim.api.nvim_win_hide(window.wh)
    end
end

window.config = function(height)
    return {
        relative = "editor",
        border = nil,
        style = 'minimal',
        width = vim.o.columns,
        height = height + opts.offset,
        row = vim.o.lines - 2,
        col = 0
    }
end

window.init = function()
    window.buffer = vim.api.nvim_create_buf(false, true)
    window.wh = vim.api.nvim_open_win(window.buffer, false, window.config(1))
    window.hide()
end

window.refresh = function(height, clear_buffer)
    if vim.api.nvim_buf_is_valid(window.buffer) == false then
        window.buffer = vim.api.nvim_create_buf(false, true)
    end

    if vim.api.nvim_win_is_valid(window.wh) == false then
        window.wh = vim.api.nvim_open_win(window.buffer, false, window.config(height))
    else
        vim.api.nvim_win_set_config(window.wh, window.config(height))
    end

    if clear_buffer then
        local tbl = {}

        for _ = 1, height do
            tbl[#tbl + 1] = (" "):rep(tonumber(vim.o.columns, 10))
        end

        vim.api.nvim_buf_set_lines(window.buffer, 0, height, false, tbl)
    end

    vim.api.nvim_command([[redraw]])
end

local init = function()
    local callback = util.debounce(function()

        if util.disable_cmdline_change then
            util.disable_cmdline_change = false
            return
        end

        local input = vim.fn.getcmdline()
        local completions = vim.fn.getcompletion(input, "cmdline")

        if opts.match_fuzzy and input ~= '' then
            local split = vim.split(input, ' ')
            local match = split[#split]
            if match:len() >= 1 then
                completions = vim.fn.matchfuzzy(completions, match)
            end
        end

        local height = math.floor(vim.o.lines * 0.3)
        local col_width = util.col_width()
        local columns = math.floor(tonumber(vim.o.columns, 10) / col_width)

        completions = vim.tbl_map(function(el)
            local is_directory = vim.fn.isdirectory(vim.fn.fnamemodify(el, ":p")) == 1
            local mod = vim.fn.fnamemodify(el, ":p:t")

            local disp

            if mod == "" then
                disp = vim.fn.fnamemodify(el, ":p:h:t")
            else
                disp = mod
            end

            if string.len(disp) >= col_width then
                disp = string.sub(disp, 1, col_width - 5) .. "..."
            end

            return {
                display = disp,
                completion = el,
                is_dir = is_directory
            }
        end, completions) or {}

        window.refresh(height, true)

        util.current_completions = {}
        util.current_selection = -1

        if vim.tbl_isempty(completions) then
            window.hide()
            return
        end

        local true_height = #completions

        local i = 1
        for line = 0, height - 1 do
            for col = 0, columns - 1 do
                if i > #completions then
                    break
                end

                local end_col = col * col_width + string.len(completions[i].display)

                if end_col > tonumber(vim.o.columns, 10) then
                    true_height = true_height + 1
                    break
                end

                vim.api.nvim_buf_set_text(window.buffer, line, col * col_width, line, end_col, {
                    completions[i].display
                })

                util.current_completions[i] = {
                    start  = { line, col * col_width },
                    finish = { line, end_col },
                    completion = completions[i].completion
                }

                if i == util.current_selection and opts.highlight_selection then
                    vim.highlight.range(
                        window.buffer,
                        util.search_hl,
                        opts.selection_hl,
                        { line, col * col_width },
                        { line, end_col },
                        {}
                    )
                end

                if completions[i].is_dir and opts.highlight_directories then
                    vim.highlight.range(
                        window.buffer,
                        util.dir_hl,
                        opts.directory_hl,
                        { line, col * col_width },
                        { line, end_col },
                        {}
                    )
                end

                i = i + 1
            end
        end

        true_height = math.ceil(true_height / math.floor(tonumber(vim.o.columns, 10) / col_width))

        if true_height < height then
            window.refresh(true_height, false)
        end

        vim.api.nvim_command([[redraw]])
    end, opts.debounce_ms)

    util.cmdline_changed = vim.api.nvim_create_autocmd({ 'CmdlineChanged' }, {
        callback = callback
    })

    callback()
end

util.tab = function(num)
    if vim.tbl_isempty(util.current_completions) then
        util.current_selection = 1
        return
    end

    if util.current_selection == -1 then
        util.current_selection = 1
    else
        util.current_selection = util.current_selection + num
        if util.current_selection > #util.current_completions then
            util.current_selection = 1
        elseif util.current_selection == 0 then
            util.current_selection = #util.current_completions
        end
    end

    vim.api.nvim_buf_clear_namespace(window.buffer, util.search_hl, 0, -1)

    vim.highlight.range(
        window.buffer,
        util.search_hl,
        opts.selection_hl,
        util.current_completions[util.current_selection].start,
        util.current_completions[util.current_selection].finish
    )

    vim.api.nvim_command([[redraw]])

    vim.schedule(function()
        util.disable_cmdline_change = true
    end)

    local cmdline = vim.fn.getcmdline()
    local split = vim.split(cmdline, ' ')

    split[#split] = util.current_completions[util.current_selection].completion

    vim.fn.setcmdline(table.concat(split, ' '))
end

local setup = function(config)
    config = config or {}
    for key, value in pairs(config) do
        opts[key] = value
    end

    window.init()

    vim.keymap.set('c', "<Tab>", function() util.tab(1) end)
    vim.keymap.set('c', "<S-Tab>", function() util.tab(-1) end)

    vim.api.nvim_create_autocmd({ "CmdwinEnter" }, {
        callback = function()
            if util.timeout then
                util.timeout:stop()
                util.timeout:close()
                util.timeout = nil
            end
            vim.schedule(function()
                window.hide()
                util.del_autocmd()
            end)
        end
    })

    vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
        callback = function()
            if vim.v.event.cmdtype == ':' then
                init()
            end
        end
    })

    vim.api.nvim_create_autocmd({ "CmdlineLeave" }, {
        callback = function()
            if vim.v.event.cmdtype == ':' then
                if util.timeout then
                    util.timeout:stop()
                    util.timeout:close()
                    util.timeout = nil
                end
                vim.schedule(function()
                    window.hide()
                    util.del_autocmd()
                end)
            end
        end
    })
end

return setup
