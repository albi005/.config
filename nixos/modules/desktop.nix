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
        enable = true;

        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;

        layout = "us,hu";
        xkbOptions = "caps:swapescape";

        # Disable mouse acceleration
        libinput.mouse.accelProfile = "flat";
    };

    # Disable GNOME default apps
    services.gnome.core-utilities.enable = false;

    environment.systemPackages = with pkgs; [
    ];

    programs.firefox.enable = true;

    users.users.albi.packages = with pkgs; [
        alacritty
        caprine-bin
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
        libsForQt5.kruler
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
