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
    match_fuzzy = true,
    highlight_selection = true,
    selection_hl = "PmenuSel",
    highlight_directories = true,
    directory_hl = "Directory",
    max_col_num = 6,
    min_col_width = 20,
    debounce_ms = 10,
    default_hl = "Pmenu",
    highlight_substr = true,
    substr_hl = "LineNr"
    offset = 1 -- depending on 'cmdheight' you might have to change the height offset
})
```

# Acknowledgements
> [smolck/command-completion.nvim](https://github.com/smolck/command-completion.nvim) for doing most of the dirty work

> [Helix](https://github.com/helix-editor/helix) for having a cool command-line
