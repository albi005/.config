-- `:Inspect` show the highlight groups under the cursor
-- `:InspectTree` show the parsed syntax tree ("TSPlayground")
-- `:EditQuery` open the Live Query Editor
-- :so $VIMRUNTIME/syntax/hitest.vim => show currently active highlight groups

-- https://github.com/lucassperez/dotfiles/blob/a1430ce1c4a4f166b247bc00b6bb0bf1b3d38c21/nvim/lua/plugins/catppuccin.lua

require('catppuccin').setup({
    flavor = 'mocha',
    transparent_background = false,
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

    -- C.none is transparent
    custom_highlights = function(C)
        return {
            HarpoonWindow = { bg = C.none },
            Normal = { bg = C.none },
            NormalNC = { bg = C.none },
        }
    end,
})

vim.cmd.colorscheme('catppuccin')
