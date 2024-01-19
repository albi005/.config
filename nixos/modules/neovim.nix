{ config, lib, pkgs, ... }:
{
    programs.neovim = {
        enable = true;
        defaultEditor = true;
        configure.packages.cum = with pkgs.vimPlugins; {
            start = [
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

    environment = {
        systemPackages = with pkgs; [
            gopls
            lua-language-server
            nil
            nixd
            nodePackages_latest.pyright
        ];
    };
}
