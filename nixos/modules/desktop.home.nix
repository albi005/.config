{ pkgs, config, ... }:
{
    gtk = {
        enable = true;
        theme = {
            name = "Catppuccin-Mocha-Compact-Green-Dark";
            package = pkgs.catppuccin-gtk.override {
                accents = [ "green" ];
                size = "compact";
                variant = "mocha";
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

    # hyprctl setcursor 'Catppuccin-Mocha-Light-Cursors' 24
    home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.catppuccin-cursors.mochaLight;
        name = "Catppuccin-Mocha-Light-Cursors";
        size = 24;
    };

    # symlink the `~/.config/gtk-4.0/` folder
    # https://github.com/catppuccin/gtk#for-nix-users
    xdg.configFile = {
        "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
        "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    };
}
