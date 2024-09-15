-- https://github.com/folke/neodev.nvim#readme
require'neodev'.setup{
    library = { plugins = { 'nvim-dap-ui' }, types = true },
}

-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/tutorial.md#complete-code
----
-- LSP setup
----
local lsp_zero = require'lsp-zero'

lsp_zero.on_attach(function(client, bufnr)
    -- see :help lsp-zero-keybindings
    -- to learn the available actions
    lsp_zero.default_keymaps{ buffer = bufnr }
end)

-- yoink icons from lualine
lsp_zero.set_sign_icons(require'lualine.components.diagnostics.config'.symbols.icons)

-- (Optional) configure lua language server
local lua_opts = lsp_zero.nvim_lua_ls()
require'lspconfig'.lua_ls.setup(lua_opts)

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- Add servers to ~/.config/nixos/modules/neovim.nix
lsp_zero.setup_servers{
    'bashls',
    'gopls',
    'nil_ls',
    'pyright',
    'rust_analyzer',
    'tsserver',
}

-- Fix "Multiple different client offset_encodings detected"
-- https://www.reddit.com/r/neovim/comments/12qbcua/comment/jgpqxsp
local cmp_nvim_lsp = require'cmp_nvim_lsp'
require'lspconfig'.clangd.setup{
    capabilities = cmp_nvim_lsp.default_capabilities(),
    cmd = {
        'clangd',
        '--offset-encoding=utf-16',
    },
}

local omnisharp_path = os.getenv'OMNISHARP_PATH'
if omnisharp_path == nil then
    print'OMNISHARP_PATH not set'
    return
end

require'lspconfig'.omnisharp.setup{
    cmd = { omnisharp_path .. '/bin/OmniSharp' },

    -- Enables support for reading code style, naming convention and analyzer
    -- settings from .editorconfig.
    enable_editorconfig_support = true,

    -- If true, MSBuild project system will only load projects for files that
    -- were opened in the editor. This setting is useful for big C# codebases
    -- and allows for faster initialization of code navigation features only
    -- for projects that are relevant to code that is being edited. With this
    -- setting enabled OmniSharp may load fewer projects and may thus display
    -- incomplete reference lists for symbols.
    enable_ms_build_load_projects_on_demand = false,

    -- Enables support for roslyn analyzers, code fixes and rulesets.
    enable_roslyn_analyzers = true,

    -- Specifies whether 'using' directives should be grouped and sorted during
    -- document formatting.
    organize_imports_on_format = true,

    -- Enables support for showing unimported types and unimported extension
    -- methods in completion lists. When committed, the appropriate using
    -- directive will be added at the top of the current file. This option can
    -- have a negative impact on initial completion responsiveness,
    -- particularly for the first few completion sessions after opening a
    -- solution.
    enable_import_completion = true,

    -- Specifies whether to include preview versions of the .NET SDK when
    -- determining which version to use for project loading.
    sdk_include_prereleases = true,

    -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
    -- true
    analyze_open_documents_only = false,

    file_types = { 'cs', 'cshtml', 'razor', 'cool', 'vb' },
}

----
-- Autocompletion config
----
local cmp = require'cmp'
local cmp_action = lsp_zero.cmp_action()

-- load snippets from rafamadriz/friendly-snippets
require'luasnip.loaders.from_vscode'.lazy_load()

-- From https://lsp-zero.netlify.app/v3.x/template/opinionated
cmp.setup{
    -- if you don't know what is a "source" in nvim-cmp read this:
    -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/autocomplete.md#adding-a-source
    sources = {
        { name = 'path' },
        { name = 'nvim_lsp' },
        { name = 'luasnip', keyword_length = 2 },
        { name = 'buffer',  keyword_length = 3 },
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    -- default keybindings for nvim-cmp are here:
    -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/README.md#keybindings-1
    mapping = cmp.mapping.preset.insert{
        -- confirm completion item
        ['<Enter>'] = cmp.mapping.confirm{ select = true },

        -- trigger completion menu
        ['<C-Space>'] = cmp.mapping.complete(),

        -- scroll up and down the documentation window
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),

        -- navigate between snippet placeholders
        ['<C-f>'] = cmp_action.luasnip_jump_forward(),
        ['<C-b>'] = cmp_action.luasnip_jump_backward(),
    },
    -- note: if you are going to use lsp-kind (another plugin)
    -- replace the line below with the function from lsp-kind
    formatting = lsp_zero.cmp_format{ details = true },
    snippet = {
        expand = function(args)
            require'luasnip'.lsp_expand(args.body)
        end,
    },
}

require'Comment'.setup()

-- https://github.com/zbirenbaum/copilot.lua#readme
-- https://github.com/zbirenbaum/copilot-cmp#readme
require('copilot_cmp').setup()
require("copilot").setup({
  -- suggestion = { enabled = false },
  -- panel = { enabled = false },
})
