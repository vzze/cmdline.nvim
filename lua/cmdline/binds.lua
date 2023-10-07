local binds = {}

binds.currentCompletions = {}
binds.currentSelection = -1
binds.visualMode = false
binds.disableUpdate = false
binds.windowRef = nil
binds.configRef = nil

binds.incrementSelection = function(num)
    if binds.currentSelection == -1 then
        binds.currentSelection = 1
    else
        binds.currentSelection = binds.currentSelection + num
        if binds.currentSelection > #binds.currentCompletions then
            binds.currentSelection = 1
        elseif binds.currentSelection == 0 then
            binds.currentSelection = #binds.currentCompletions
        end
    end
end

binds.updateCmdline = function()
    vim.schedule(function()
        vim.cmd([[redraw]])
    end)

    vim.schedule(function()
        binds.disableUpdate = true
    end)

    local cmdline = vim.fn.getcmdline()

    local split = vim.split(cmdline, ' ')

    if #split == 1 and binds.visualMode then
        split[#split] = "'<,'>" .. binds.currentCompletions[binds.currentSelection].completion
    else
        split[#split] = binds.currentCompletions[binds.currentSelection].completion
    end


    vim.fn.setcmdline(table.concat(split, ' '))
end

binds.update = function(num)
    if vim.tbl_isempty(binds.currentCompletions) then
        binds.currentSelection = 1
        return
    end

    binds.incrementSelection(num)

    vim.api.nvim_buf_clear_namespace(
        binds.windowRef.buffer,
        binds.windowRef.ns.search,
        0, -1
    )

    binds.windowRef.hl.search(
        binds.currentCompletions[binds.currentSelection].start,
        binds.currentCompletions[binds.currentSelection].finish,
        binds.configRef.opts.hl.selection
    )

    binds.updateCmdline()
end

binds.init = function(configRef, windowRef)
    binds.configRef = configRef
    binds.windowRef = windowRef

    vim.keymap.set(
        'c',
        configRef.opts.binds.next,
        function() binds.update(1) end
    )

    vim.keymap.set(
        'c',
        configRef.opts.binds.back,
        function() binds.update(-1) end
    )
end

return binds
