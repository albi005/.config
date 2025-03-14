require'lualine'.setup{
    options = {
        theme = 'catppuccin'
    },

    -- Show full path: https://github.com/nvim-lualine/lualine.nvim/issues/271
    sections = {
        lualine_c = {
            {
                'filename',
                file_status = true, -- displays file status (readonly status, modified status)
                path = 2 -- 0 = just filename, 1 = relative path, 2 = absolute path
            }
        }
    }
}
