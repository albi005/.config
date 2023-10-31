{ config, pkgs, ... }:
{
    # Set your time zone.
    time.timeZone = "Europe/Budapest";

    # Select internationalisation properties.
    i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
            LC_ADDRESS = "hu_HU.UTF-8";
            LC_IDENTIFICATION = "hu_HU.UTF-8";
            LC_MEASUREMENT = "hu_HU.UTF-8";
            LC_MONETARY = "hu_HU.UTF-8";
            LC_NAME = "hu_HU.UTF-8";
            LC_NUMERIC = "hu_HU.UTF-8";
            LC_PAPER = "hu_HU.UTF-8";
            LC_TELEPHONE = "hu_HU.UTF-8";
            LC_TIME = "hu_HU.UTF-8";
        };
    };

    services.xserver = {
        # Enable the X11 windowing system.
        enable = true;

        # Enable the GNOME Desktop Environment.
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;

        layout = "us,hu";

        xkbOptions = "caps:swapescape";
    };

    # Disable GNOME default apps
    services.gnome.core-utilities.enable = false;

    environment.systemPackages = with pkgs; [
    ];

    users.users.albi.packages = with pkgs; [
        alacritty
        cinnamon.nemo-with-extensions
        gimp
        gnome.file-roller
        gnome.gnome-disk-utility
        gnome.gnome-tweaks
        gnome.totem
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.headsetcontrol
        gnomeExtensions.openweather
        gnomeExtensions.twitchlive-panel
        google-chrome
        headsetcontrol
        jetbrains.rider
        libreoffice
        obsidian
        remmina
        sqlitebrowser
        vscode
    ];

    fonts.packages = with pkgs; [
        (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
        corefonts
    ];
}
