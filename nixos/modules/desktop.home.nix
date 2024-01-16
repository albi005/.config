{ pkgs, ... }:
{
    # TODO: GTK theme
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
    };
}
