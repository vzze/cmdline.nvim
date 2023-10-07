local config = {}

config.opts = {
    window = {
        matchFuzzy = true,
        offset     = 1,
        debounceMs = 10
    },

    hl = {
        default   = "Pmenu",
        selection = "PmenuSel",
        directory = "Directory",
        substr    = "LineNr"
    },

    column = {
        maxNumber = 6,
        minWidth  = 20
    },

    binds = {
        next = "<Tab>",
        back = "<S-Tab>"
    }
}

config.user = {}

config.user.setOptsGroup = function(cfg, group)
    if cfg[group] then
        for key, value in pairs(cfg[group]) do
            cfg.opts[group][key] = value
        end
    end
end

config.user.setOpts = function(cfg)
    if not cfg then
        return
    end

    config.user.setOptsGroup(cfg, "window")
    config.user.setOptsGroup(cfg, "hl")
    config.user.setOptsGroup(cfg, "column")
    config.user.setOptsGroup(cfg, "binds")
end

return config
