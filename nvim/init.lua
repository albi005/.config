vim.g.mapleader = ' ' -- set what <Leader> means in keybinds
vim.o.exrc = true     -- source .nvim.lua files

require'init.colors'

-- HARPOON -- quick file list
do
    local harpoon = require'harpoon'
    harpoon:setup()

    vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end)
    vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

    vim.keymap.set('n', '<C-h>', function() harpoon:list():select(1) end)
    vim.keymap.set('n', '<C-t>', function() harpoon:list():select(2) end)
    vim.keymap.set('n', '<C-n>', function() harpoon:list():select(3) end)
    vim.keymap.set('n', '<C-s>', function() harpoon:list():select(4) end)

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<C-S-P>', function() harpoon:list():prev() end)
    vim.keymap.set('n', '<C-S-N>', function() harpoon:list():next() end)
end


-- LSP -- https://lsp-zero.netlify.app/docs/getting-started.html#extend-nvim-lspconfig

-- Reserve a space in the gutter
-- This will avoid an annoying layout shift in the screen
vim.opt.signcolumn = 'yes'

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require'lspconfig'.util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
    'force',
    lspconfig_defaults.capabilities,
    require'cmp_nvim_lsp'.default_capabilities()
)

-- This is where you enable features that only work
-- if there is a language server active in the file
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
    end,
})

require'lspconfig'.lua_ls.setup{}

local cmp = require'cmp'

cmp.setup{
    sources = {
        { name = 'nvim_lsp' },
    },
    snippet = {
        expand = function(args)
            -- You need Neovim v0.10 to use vim.snippet
            vim.snippet.expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert{},
}

-- https://github.com/zbirenbaum/copilot.lua#readme
-- https://github.com/zbirenbaum/copilot-cmp#readme
-- require'copilot_cmp'.setup()
-- require'copilot'.setup{
--     suggestion = { enabled = false },
--     panel = { enabled = false },
-- }
--
-- require'copilot_cmp'.setup()
