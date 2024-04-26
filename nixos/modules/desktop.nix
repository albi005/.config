{ config, pkgs, ... }:
{
    services.xserver = {
        enable = true;

        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;

        xkb = {
            layout = "us,hu";
            options = "caps:swapescape";
        };

        # Disable mouse acceleration
        libinput.mouse.accelProfile = "flat";
    };

    # Disable default GNOME apps
    services.gnome.core-utilities.enable = false;

    programs.firefox.enable = true;
    programs.wireshark.enable = true;

    users.users.albi.packages = with pkgs; [
        alacritty
        beeper #All your chats in one app
        bluetuith #bluetooth manager tui
        cinnamon.nemo-with-extensions
        dbeaver
        ffmpeg-full
        filelight
        gimp
        gnome.file-roller
        gnome.gnome-disk-utility
        gnome.totem
        google-chrome
        headsetcontrol
        kitty
        libreoffice
        libsForQt5.kruler
        loupe #image viewer
        obsidian
        qdirstat
        remmina
        sqlitebrowser
        thunderbird
        vscode
        wezterm
        wireshark

        catppuccin-cursors.mochaDark
        papirus-icon-theme
        #lxappearance # Segmentation fault (core dumped)
    ];

    # https://nixos.wiki/wiki/Home_Manager#I_cannot_set_GNOME_or_Gtk_themes_via_home-manager
    programs.dconf.enable = true;

    home-manager.users.albi = import ./desktop.home.nix;

    fonts = {
        packages = with pkgs; [
            (nerdfonts.override { fonts = [ "CascadiaCode" "NerdFontsSymbolsOnly" ]; })
            cantarell-fonts #GNOME font
            cascadia-code
            corefonts #Microsoft web fonts
            roboto
            roboto-slab
        ];
        fontconfig.defaultFonts = {
            sansSerif = ["Roboto"];
            serif = ["Roboto Slab"];
            monospace = ["Cascadia Code"];
        };
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    hardware.bluetooth.enable = true;

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

    services.udev.packages = [ pkgs.headsetcontrol ];

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
