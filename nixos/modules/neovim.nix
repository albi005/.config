{ config, lib, pkgs, ... }:
{
    environment = {
        systemPackages = with pkgs; [
            gopls
            lua-language-server
            neovim
            nil
            nixd
            nodePackages.pyright
            nodePackages.bash-language-server
            bashdb #bash debug adapter
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
                lualine-nvim
                neodev-nvim #nvim api types
                nvim-autopairs
                nvim-dap
                nvim-dap-ui
                nvim-dap-virtual-text
                nvim-treesitter.withAllGrammars
                nvim-web-devicons
                pkgs.luajitPackages.nvim-nio#required by nvim-dap-ui
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
                export BASHDB_PATH="${pkgs.bashdb}"
            '';
        };
    };
}
