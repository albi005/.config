{ config, lib, pkgs, ... }:
{
    environment = {
        systemPackages = with pkgs; [
            gopls
            lua-language-server
            neovim
            nil
            nixd
            nodePackages_latest.pyright
        ];
    };

    home-manager.users.albi = { config, pkgs, ... }:
    {
        programs.neovim = {
            enable = true;
            plugins = with pkgs.vimPlugins; [
                catppuccin-nvim
                comment-nvim
                copilot-cmp
                copilot-lua
                harpoon
                nvim-autopairs
                nvim-dap
                nvim-dap-ui
                nvim-treesitter.withAllGrammars
                telescope-nvim
                undotree
                vim-illuminate #highlight symbol under the cursor
                vim-wakatime
                which-key-nvim

                lsp-zero-nvim
                  # LSP
                  nvim-lspconfig
                  # Autocomplete
                  nvim-cmp
                  cmp-nvim-lsp
                  luasnip

                clangd_extensions-nvim
            ];
        };

        programs.bash = {
            bashrcExtra = ''
                export OMNISHARP_PATH="${pkgs.omnisharp-roslyn}"
            '';
        };
    };
}
