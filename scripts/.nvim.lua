local dap = require('dap')

dap.configurations.cpp = {
    {
        name = "Run C++ program",
        type = "cppdbg",
        request = "launch",
        program = function()
            local dir = vim.fn.expand('%:p:h')
            local cmd = '!TARGET=a.out make --environment-overrides --directory ' .. dir
            vim.cmd(cmd)
            return dir .. "/a.out"
        end,
        cwd = function()
            local dir = vim.fn.expand('%:p:h')
            return dir
        end,
        stopAtEntry = false,
        setupCommands = {
            {
                text = '-enable-pretty-printing',
                description = 'enable pretty printing',
                ignoreFailures = false
            },
        },
    },
}

dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = 'executable',
    command = os.getenv 'OPEN_DEBUG_PATH',
}

local function currentFileFullPath() -- /home/albi/src/scripts
    return vim.fn.expand('%:p')
end

local function currentDirFullPath() -- /home/albi/src/scripts/test.py
    return vim.fn.expand('%:p:h')
end

-- run python script
vim.keymap.set('n', '<Leader>r', function()
    vim.cmd':w'
    vim.cmd('!(cd ' .. currentDirFullPath() .. ' && python3 ' .. currentFileFullPath() .. ')')
end)

-- run python script in an interactive shell
vim.keymap.set('n', '<Leader>t', function()
    vim.cmd':w'
    vim.cmd(':te (cd ' .. currentDirFullPath() .. ' && python3 ' .. currentFileFullPath() .. ')')
end)
