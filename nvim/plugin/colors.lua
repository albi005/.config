-- https://github.com/lucassperez/dotfiles/blob/a1430ce1c4a4f166b247bc00b6bb0bf1b3d38c21/nvim/lua/plugins/catppuccin.lua
vim.g.catppuccin_flavour = 'mocha'

require('catppuccin').setup({
    transparent_background = true,
    styles = {
        comments = {},
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
    },

    -- https://github.com/catppuccin/nvim/#integrations
    integrations = {
        treesitter = true,
        harpoon = true,
        native_lsp = {
            enabled = true,
        },
        cmp = true,
        telescope = true,
        nvimtree = false,
        dap = true,
        dap_ui = true,
        illuminate = {
            enabled = true,
            lsp = true
        }
    },

    custom_highlights = function(colors)
        return {}
    end,
})

vim.cmd.colorscheme('catppuccin')

-- Draw terminal bg color for nvim bg => makes only the background color transparent -- https://reddit.com/r/neovim/comments/waf3w4
--vim.cmd'hi Normal guibg=NONE ctermbg=NONE'

-- Add :LspInfo border -- https://vi.stackexchange.com/q/39000
require('lspconfig.ui.windows').default_options.border = 'single'
