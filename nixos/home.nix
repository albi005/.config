{ config, pkgs, ... }:
{
    home.stateVersion = "23.05";

# enable if dconf not found:
# programs.dconf.enable = true;

    xsession.enable = true;
    xsession.windowManager.command = "...";

    programs.git = {
        enable = true;
        userName = "Albert Ragány-Németh";
        userEmail = "me@alb1.hu";
        extraConfig = {
            init.defaultBranch = "main";
        };
    };

    programs.alacritty = {
        enable = true;
        settings = {
            font = {
                normal = {
                    family = "CaskaydiaCove Nerd Font";
                    style = "Regular";
                };
                bold = {
                    family = "CaskaydiaCove Nerd Font";
                    style = "Bold";
                };
                italic = {
                    family = "CaskaydiaCove Nerd Font";
                    style = "Italic";
                };
                bold_italic = {
                    family = "CaskaydiaCove Nerd Font";
                    style = "Bold Italic";
                };
                size = 11;
            };
        };
    };

    programs.tmux = {
        enable = true;
        escapeTime = 0;
        mouse = true;

        # needed, otherwise colors in tmux in alacritty are wrong
        extraConfig = "set-option -ga terminal-overrides ',alacritty:Tc'";
    };

    programs.bash = {
        enable = true;

        shellAliases = {
            l = "lsd -Al --group-directories-first --date '+%Y-%m-%d %H:%M'";
            tree = "lsd --tree --group-directories-first --date '+%Y-%m-%d %H:%M'";
            v = "nvim .";
            c = "clear";
            c-vim = "nvim ~/.config/nvim";
            c-bash = "nvim ~/.profile && source ~/.profile";
            c-nix = "nvim ~/.config/nixos";
            rb = "sudo nixos-rebuild switch";
            colors = "curl -s https://gist.githubusercontent.com/grhbit/db6c5654fa976be33808b8b33a6eb861/raw/1875ff9b84a014214d0ce9d922654bb34001198e/24-bit-color.sh | bash";
            ports = "sudo netstat -tulpn";
        };

        sessionVariables = {
            PATH = "$PATH:/home/albi/.dotnet/tools";
        };
    };
}
