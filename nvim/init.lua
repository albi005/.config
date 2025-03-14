vim.g.mapleader = ' ' -- set what <Leader> means in keybinds
vim.o.exrc = true -- source .nvim.lua files

require'init.colors' -- catppuccin
require'init.lualine' -- bottom status bar
require'init.harpoon' -- quick file list

-- --
-- Language servers (LSP) -- https://lsp-zero.netlify.app/docs/getting-started.html#extend-nvim-lspconfig
-- --

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
require'lspconfig'.nil_ls.setup{} -- Nix LSP, better
-- require'lspconfig'.nixd.setup{} -- Nix LSP
require'lspconfig'.html.setup{}

do -- C# and Razor
    -- https://github.com/tris203/rzls.nvim#example-config
    vim.filetype.add{
        extension = {
            razor = 'razor',
            cshtml = 'razor',
        },
    }

    require'rzls'.setup{
        path = os.getenv'RZLS_PATH' .. '/bin/rzls',
    }

    local dotnet_path = os.getenv'DOTNET_SDK_PATH' -- /nix/store/y20wcqi704x58v394scs6cyvay6x0x86-dotnet-sdk-wrapped-9.0.200/share/dotnet/sdk/9.0.200/Sdks/Microsoft.NET.Sdk.Razor/
    if dotnet_path then
        local dotnet_version = string.sub(dotnet_path, 64, 70)
        local razor_sdk_path = dotnet_path .. '/share/dotnet/sdk/' .. dotnet_version .. '/Sdks/Microsoft.NET.Sdk.Razor'

        require'roslyn'.setup{
            exe = 'Microsoft.CodeAnalysis.LanguageServer',
            args = {
                '--stdio',
                '--logLevel=Information',
                '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
                '--razorSourceGenerator='
                .. razor_sdk_path .. '/tools/Microsoft.CodeAnalysis.Razor.Compiler.dll',
                '--razorDesignTimePath=' .. razor_sdk_path .. '/targets/Microsoft.NET.Sdk.Razor.DesignTime.targets',
            },
            ---@diagnostic disable-next-line: missing-fields
            config = {
                handlers = require'rzls.roslyn_handlers',
                settings = {
                    ['csharp|inlay_hints'] = {
                        csharp_enable_inlay_hints_for_implicit_object_creation = true,
                        csharp_enable_inlay_hints_for_implicit_variable_types = true,

                        csharp_enable_inlay_hints_for_lambda_parameter_types = true,
                        csharp_enable_inlay_hints_for_types = true,
                        dotnet_enable_inlay_hints_for_indexer_parameters = true,
                        dotnet_enable_inlay_hints_for_literal_parameters = true,
                        dotnet_enable_inlay_hints_for_object_creation_parameters = true,
                        dotnet_enable_inlay_hints_for_other_parameters = true,
                        dotnet_enable_inlay_hints_for_parameters = true,
                        dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
                        dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
                        dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
                    },
                    ['csharp|code_lens'] = {
                        dotnet_enable_references_code_lens = true,
                    },
                },
            },
        }
    end
end

do -- completion
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
end


-- https://github.com/zbirenbaum/copilot.lua#readme
-- https://github.com/zbirenbaum/copilot-cmp#readme
-- require'copilot_cmp'.setup()
-- require'copilot'.setup{
--     suggestion = { enabled = false },
--     panel = { enabled = false },
-- }
--
-- require'copilot_cmp'.setup()
