{ pkgs, ... }:
{
  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BASHDB_PATH = "${pkgs.bashdb}";
      OMNISHARP_PATH = "${pkgs.omnisharp-roslyn}";
    };
    systemPackages = with pkgs; [
      bashdb # bash debug adapter
      gopls
      lua-language-server
      neovim
      nil
      nixd
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      pyright
      typescript
    ];
  };

  home-manager.users.albi =
    { config, pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        extraLuaPackages =
          luaPkgs: with luaPkgs; [
            luautf8
            nvim-nio # required by nvim-dap-ui
          ];
        plugins = with pkgs.vimPlugins; [
          catppuccin-nvim
          comment-nvim
          copilot-cmp
          copilot-lua
          friendly-snippets
          harpoon
          indent-blankline-nvim
          lualine-nvim
          neodev-nvim # nvim api types
          nvim-autopairs
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          nvim-treesitter.withAllGrammars
          nvim-web-devicons
          telescope-nvim
          undotree
          vim-illuminate # highlight symbol under the cursor
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
    };
}
