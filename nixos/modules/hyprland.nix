{ lib, config, pkgs, ... }:
{
    programs.hyprland.enable = true;
    programs.kdeconnect.enable = true;
    security.polkit.enable = true;
    services.gvfs.enable = true;
    services.samba.enable = true;

    environment.systemPackages = with pkgs; [
        hyprpicker
        waybar
        hyprpaper
        wofi
        font-awesome
        xfce.thunar
        rofi
        libsForQt5.polkit-kde-agent
        clipcat
        filezilla
        brightnessctl

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

        gnome.nautilus

        # TODO: Remove unneeded screenshot stuff
        # Screenshot stuff, https://github.com/jtheoof/swappy
        wl-clipboard
        grim
        slurp
        swappy


        # more screenshot stuff
        grimblast
    ];

    # TODO: QT style?
    qt.style = "adwaita-dark";

    # Disable GNOME stuff
    services.xserver.enable = lib.mkForce false;
    services.xserver = {
        displayManager.gdm.enable = lib.mkForce false;
        desktopManager.gnome.enable = lib.mkForce false;
    };

    home-manager.users.albi = { ... }: {
        home.file.".config/hypr/host.conf".text = lib.mkDefault "";
    };
}

