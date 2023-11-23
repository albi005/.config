local dap = require('dap')

vim.keymap.set('n', "<C-b>", dap.toggle_breakpoint)
vim.keymap.set('n', "<F5>", dap.continue)
vim.keymap.set('n', "<F8>", dap.step_over)
vim.keymap.set('n', "<F9>", dap.step_into)
vim.keymap.set('n', "<F10>", dap.step_out)

-- https://github.com/rcarriga/nvim-dap-ui
require("dapui").setup()

local dapui = require("dapui")
dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
end

