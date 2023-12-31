{ config, pkgs, ... }:
{
    services.xserver = {
        enable = true;

        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;

        layout = "us,hu";
        xkbOptions = "caps:swapescape";

        # Disable mouse acceleration
        libinput.mouse.accelProfile = "flat";
    };

    # Disable default GNOME apps
    services.gnome.core-utilities.enable = false;

    programs.firefox.enable = true;

    users.users.albi.packages = with pkgs; [
        alacritty
        caprine-bin
        cinnamon.nemo-with-extensions
        dbeaver
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

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
    };

    time.timeZone = "Europe/Budapest";

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
}
