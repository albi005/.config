-- https://github.com/zbirenbaum/copilot.lua#readme
-- https://github.com/zbirenbaum/copilot-cmp#readme
require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})
require('copilot_cmp').setup()
