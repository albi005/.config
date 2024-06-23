local dap = require('dap')

-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#python
dap.adapters.python = function(cb, config)
  if config.request == 'attach' then
    local port = (config.connect or config).port
    local host = (config.connect or config).host or '127.0.0.1'
    cb({
      type = 'server',
      port = assert(port, '`connect.port` is required for a python `attach` configuration'),
      host = host,
      options = {
        source_filetype = 'python',
      },
    })
  else
    cb({
      type = 'executable',
      command = 'python3',
      args = { '-m', 'debugpy.adapter' },
      options = {
        source_filetype = 'python',
      },
    })
  end
end

dap.configurations.python = {
  {
    -- The first three options are required by nvim-dap
    type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = 'launch';
    name = "Launch file";
    cwd = '/mnt',
    program = "${file}"; -- This configuration will launch the current file if used.
  }
}

-- dap.configurations.python = {
--     {
--         name = "Run Python program",
--         type = "",
--         request = "launch",
--         program = function()
--             local dir = vim.fn.expand('%:p:h')
--             local cmd = '!TARGET=a.out make --environment-overrides --directory ' .. dir
--             vim.cmd(cmd)
--             return dir .. "/a.out"
--         end,
--         cwd = function()
--             local dir = vim.fn.expand('%:p:h')
--             return dir
--         end,
--         stopAtEntry = false,
--         setupCommands = {
--             {
--                 text = '-enable-pretty-printing',
--                 description = 'enable pretty printing',
--                 ignoreFailures = false
--             },
--         },
--     },
-- }

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
