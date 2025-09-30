{
  pkgs,
  lib,
  ...
}: {
  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs = {
    nvf = {
      enable = true;
      enableManpages = true;
      settings = {
        # example: https://github.com/NotAShelf/nvf/blob/main/configuration.nix
        vim = {
          viAlias = true;
          vimAlias = true;

          debugMode = {
            enable = false;
            level = 16;
            logFile = "/tmp/nvim.log";
          };

          lsp = {
            enable = true;
            formatOnSave = true;
            lightbulb.enable = true; # shows a lightbulb when there are code actions
            trouble.enable = true; # diagnostics, references, telescope results, quickfix and location lists
            otter-nvim.enable = true; # language injection
            nvim-docs-view.enable = true; # :DocsViewToggle # display lsp hover documentation in a side panel
          };

          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableExtraDiagnostics = true;

            nix.enable = true;
            elixir.enable = true;
          };

          visuals = {
            nvim-scrollbar.enable = true;
            nvim-web-devicons.enable = true; # Nerd Font icons for use by neovim plugins
            fidget-nvim.enable = true; # notifications/status messages

            indent-blankline.enable = true; # indentation lines

            cellular-automaton.enable = true; # :CellularAutomaton make_it_rain
          };

          statusline = {
            lualine = {
              enable = true;
              theme = "catppuccin";
            };
          };

          theme = {
            enable = true;
            name = "catppuccin";
            style = "mocha";
            transparent = false;
          };

          autocomplete = {
            blink-cmp.enable = true;
          };

          snippets.luasnip.enable = true;

          filetree = {
            neo-tree = {
              enable = true;
            };
          };

          treesitter.context.enable = true; # sticky context

          binds = {
            whichKey.enable = true;
            cheatsheet.enable = true;
          };

          telescope.enable = true;

          dashboard = {
            alpha.enable = true;
          };

          utility = {
            vim-wakatime.enable = true;
            undotree.enable = true;
          };

          ui = {
            borders.enable = true;
            illuminate.enable = true;
          };
        };
      };
    };
  };
}
