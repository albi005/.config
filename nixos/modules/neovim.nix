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
                telescope-nvim
                harpoon
                catppuccin-nvim
                vim-wakatime
                nvim-treesitter.withAllGrammars
                copilot-lua
                copilot-cmp
                nvim-dap
                nvim-dap-ui
                comment-nvim

                # LSP
                lsp-zero-nvim
                nvim-lspconfig
                  cmp-nvim-lsp

                # Autocomplete
                nvim-cmp
                  luasnip
            ];
        };
    };
}
