-- https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)

local dap = require('dap')
dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = 'executable',
    command = '/home/albi/.local/bin/ms-vscode.cpptools-1.15.3@linux-x64/extension/debugAdapters/bin/OpenDebugAD7',
}

vim.keymap.set('n', "<C-b>", dap.toggle_breakpoint)
vim.keymap.set('n', "<F5>", dap.continue)
vim.keymap.set('n', "<F8>", dap.step_over)

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

