# cmdline.nvim
cmdline.nvim brings [Helix](https://github.com/helix-editor/helix)'s command-line to Neovim

<p align="center">
    <img src="https://raw.githubusercontent.com/vzze/cmdline.nvim/main/preview.png">
</p>

# Requirements

* Neovim 0.8.2 or later

# Setup

## Installation

Install `vzze/cmdline.nvim` with the plugin manager of your choice.

## Options
```lua
require('cmdline')({
    window = {
        matchFuzzy = true,
        offset     = 1, -- depending on 'cmdheight' you might need to offset
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
})
```

# Acknowledgements
> [smolck/command-completion.nvim](https://github.com/smolck/command-completion.nvim) for doing most of the dirty work

> [Helix](https://github.com/helix-editor/helix) for having a cool command-line
