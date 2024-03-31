local dap = require 'dap'

vim.keymap.set('n', "<C-b>", dap.toggle_breakpoint)
vim.keymap.set('n', "<F5>", dap.continue)
vim.keymap.set('n', "<F8>", dap.step_over)
vim.keymap.set('n', "<F9>", dap.step_into)
vim.keymap.set('n', "<F10>", dap.step_out)

local bashdb_path = os.getenv'BASHDB_PATH'
if bashdb_path == nil then error('BASHDB_PATH not set') end

dap.adapters.bashdb = {
    type = 'executable',
    command = 'bashdb',
    name = 'bashdb',
}
dap.configurations.sh = {
    {
        type = 'bashdb',
        request = 'launch',
        name = "Launch file",
        showDebugOutput = true,
        pathBashdb = bashdb_path .. '/bin/bashdb',
        pathBashdbLib = bashdb_path .. '/share/bashdb/lib',
        trace = true,
        file = "${file}",
        program = "${file}",
        cwd = '${workspaceFolder}',
        pathCat = "cat",
        pathBash = "bash",
        pathMkfifo = "mkfifo",
        pathPkill = "pkill",
        args = {},
        env = {},
        terminalKind = "integrated",
    }
}

require 'nvim-dap-virtual-text'.setup()

-- https://github.com/rcarriga/nvim-dap-ui
local dapui = require("dapui")
dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
end

vim.keymap.set('v', 'K', dapui.eval)
