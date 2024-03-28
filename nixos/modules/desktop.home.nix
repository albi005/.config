{ pkgs, config, ... }:
{
    gtk = {
        enable = true;
        theme = {
            name = "Catppuccin-Macchiato-Compact-Pink-Dark";
            package = pkgs.catppuccin-gtk.override {
                accents = [ "pink" ];
                size = "compact";
                variant = "macchiato";
            };
        };
        iconTheme = {
            name = "Adwaita";
            package = pkgs.gnome.adwaita-icon-theme;
        };

        # cursorTheme = {
        #     package = pkgs.catppuccin-cursors.mochaDark;
        #     name = "Catppuccin-Mocha-Dark";
        #     size = 16;
        # };
    };

    # THIS WORKS, DONT TOUCH
    # hyprctl setcursor 'Catppuccin-Mocha-Dark-Cursors' 16
    home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.catppuccin-cursors.mochaDark;
        name = "Catppuccin-Mocha-Dark-Cursors";
        size = 16;
    };

    # symlink the `~/.config/gtk-4.0/` folder
    # https://github.com/catppuccin/gtk#for-nix-users
    xdg.configFile = {
        "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
        "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    };
}
