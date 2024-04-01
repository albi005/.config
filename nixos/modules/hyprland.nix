{ lib, config, pkgs, ... }:
{
    programs.hyprland.enable = true;
    programs.kdeconnect.enable = true;
    security.polkit.enable = true;
    services.gvfs.enable = true;
    services.samba.enable = true;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    environment.systemPackages = with pkgs; [
        hyprpicker
        waybar
        hyprpaper
        wofi
        font-awesome
        xfce.thunar
        rofi-wayland
        libsForQt5.polkit-kde-agent
        clipcat
        filezilla
        brightnessctl

        glib #gsettings

        libnotify #https://youtu.be/61wGzIv12Ds?t=162
        networkmanagerapplet

        # 
        coreutils
        curl
        rsync 
        wget 
        ripgrep
        gojq
        nodejs
        meson
        typescript
        gjs
        sassc

        eww

        pavucontrol
        playerctl

        # TODO: Remove unneeded screenshot stuff
        # Screenshot stuff, https://github.com/jtheoof/swappy
        wl-clipboard
        grim
        slurp
        swappy


        # more screenshot stuff
        grimblast

        # Notification daemon
        # https://wiki.hyprland.org/Useful-Utilities/Must-have/#a-notification-daemon
        dunst

        # Authentication agent
        # https://wiki.hyprland.org/Useful-Utilities/Must-have/#authentication-agent
        kdePackages.polkit-kde-agent-1
        lxqt.lxqt-policykit

        nwg-look # gtk theme config gui
    ];

    # TODO: QT style?
    qt.style = "adwaita-dark";

    # Disable GNOME stuff
    services.xserver.enable = lib.mkForce false;
    services.xserver = {
        displayManager.gdm.enable = lib.mkForce false;
        desktopManager.gnome.enable = lib.mkForce false;
    };

    # create an empty file that can be overwritten to set host specific options
    home-manager.users.albi = { ... }: {
        home.file.".config/hypr/host.conf".text = lib.mkDefault "";
    };
}

