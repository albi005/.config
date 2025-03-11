-- needs to be set before any references to <Leader>
vim.g.mapleader = ' '

-- source .nvim.lua files
-- can't go in plugin/ because reasons
vim.o.exrc = true

-- https://github.com/zbirenbaum/copilot.lua#readme
-- https://github.com/zbirenbaum/copilot-cmp#readme
-- require'copilot_cmp'.setup()
require'copilot'.setup{
    suggestion = { enabled = false },
    panel = { enabled = false },
}

require'copilot_cmp'.setup()

