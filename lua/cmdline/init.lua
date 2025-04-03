---@diagnostic disable: undefined-field
---@diagnostic disable: need-check-nil

local cmdline = nil

local loadPlugin = function(cfg)
    cmdline = require("cmdline.cmdline")
    cmdline.init(cfg)
end

local setup = function(cfg)
    vim.api.nvim_create_autocmd({ "CmdwinEnter"}, {
        callback = function()
            if cmdline == nil then loadPlugin(cfg) end

            cmdline.onCmdwinEnter()
        end
    })

    vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
        callback = function()
            if cmdline == nil then loadPlugin(cfg) end

            cmdline.onCmdlineEnter()
        end
    })

    vim.api.nvim_create_autocmd({ "CmdlineLeave" }, {
        callback = function()
            if cmdline == nil then loadPlugin(cfg) end

            cmdline.onCmdlineLeave()
        end
    })

    vim.api.nvim_create_autocmd({ "WinLeave", "VimLeavePre" }, {
        callback = function()
            if cmdline == nil then loadPlugin(cfg) end

            cmdline.onWinLeave()
        end
    })
end

return { setup = setup }
