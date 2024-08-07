{ lib, pkgs, inputs, ... }:
{
  hardware.bluetooth.enable = true; # use with bluetuith
  programs.dconf.enable = true; # gnome settings backend https://nixos.wiki/wiki/Home_Manager#I_cannot_set_GNOME_or_Gtk_themes_via_home-manager
  programs.firefox.enable = true;
  programs.hyprland.enable = true; # Tiling compositor with the looks
  programs.kdeconnect.enable = true; # phone link
  programs.wireshark.enable = true; # network protocol analyzer
  security.polkit.enable = true; # gui sudo
  services.gnome.gnome-keyring.enable = true; # security credential store
  services.gvfs.enable = true; # GNOME Virtual file system
  services.printing.enable = true;
  services.upower.enable = true; # required by ags battery widget
  xdg.portal.enable = true; # file pickers, screen sharing and other stuff https://wiki.hyprland.org/Useful-Utilities/Must-have/#xdg-desktop-portal
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ]; # xdg-desktop-portal-wlr but better

  environment.systemPackages = with pkgs; [
    ags # js based widgets
    brightnessctl # brightnessctl s 50
    cliphist # wayland clipboard manager with support for multimedia
    dunst # notification daemon https://wiki.hyprland.org/Useful-Utilities/Must-have/#a-notification-daemon
    font-awesome
    glib # gsettings
    grimblast # hyprland screenshot program https://github.com/hyprwm/contrib/blob/main/grimblast/grimblast
    hyprpaper # wallpaper daemon
    hyprpicker # color picker
    libdbusmenu-gtk3 # needed by ags
    libnotify # used by some apps to send notifications
    lxqt.lxqt-policykit # polkit frontend https://wiki.hyprland.org/Useful-Utilities/Must-have/#authentication-agent https://reddit.com/r/NixOS/comments/171mexa/comment/k3rpftn
    nwg-look # gtk theme config gui
    pavucontrol # pulseaudio volume control
    playerctl # media player controller
    rofi-wayland # start menu
    waybar # top bar
    wl-clipboard # command-line copy/paste utilities for wayland
  ];

  users.users.albi.packages = with pkgs; [
    alacritty # terminal emulator
    beeper # all your chats in one app
    bluetuith # bluetooth manager tui
    nemo-with-extensions # file manager
    inputs.dbeaver-last.legacyPackages.x86_64-linux.pkgs.dbeaver-bin
    desktop-file-utils # needed by something
    ffmpeg-full
    file-roller # archive manager
    gimp # paint
    gnome-disk-utility # disk manager
    google-chrome
    headsetcontrol # arctis nova 7 battery check
    imhex # hex editor
    kitty # terminal emulator
    krita # painting application
    libreoffice
    libsForQt5.kruler # screen ruler
    loupe # image viewer
    obsidian # notes
    remmina # remote desktop client
    sqlitebrowser
    thunderbird # email client
    totem # videos
    vscode
    inputs.wezterm-git.packages.${pkgs.system}.default # terminal emulator
    wofi-emoji # emoji selector
    zed-editor # vscode in rust
  ];

  home-manager.users.albi =
    { pkgs, config, ... }:
    {
      # can be overridden to set host specific hyprland config, imported in hyprland.conf, empty by default
      home.file.".config/hypr/host.conf".text = lib.mkDefault "";

      # https://github.com/catppuccin/nix/blob/main/modules/home-manager/gtk.nix
      # names changed to lowercase: https://github.com/catppuccin/nix/pull/239
      # https://github.com/catppuccin/gtk/blob/23b52b5/docs/USAGE.md#manual-installation
      # catppuccin/gtk joever: https://github.com/catppuccin/gtk/issues/262
      gtk = {
        enable = true;
        theme = {
          package = pkgs.catppuccin-gtk.override {
            accents = [ "green" ];
            size = "compact";
            variant = "mocha";
          };
          name = "catppuccin-mocha-green-compact";
        };
        iconTheme = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
        };
      };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.catppuccin-cursors.mochaLight;
        name = "catppuccin-mocha-light-cursors";
        size = 24;
      };

      # symlink the `~/.config/gtk-4.0/` folder - https://github.com/catppuccin/gtk#for-nix-users
      xdg.configFile = {
        "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
        "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
      };
    };

  qt.enable = true;
  qt.style = "adwaita-dark";
  qt.platformTheme = "gnome";

  fonts = {
    packages = with pkgs; [
      (nerdfonts.override
      {
        fonts = [
          "CascadiaCode"
          "NerdFontsSymbolsOnly"
        ];
      })
      cantarell-fonts # GNOME font
      cascadia-code
      corefonts # Microsoft web fonts
      roboto
      roboto-slab
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Roboto" ];
      serif = [ "Roboto Slab" ];
      monospace = [ "Cascadia Code" ];
    };
  };

  # Enable sound with pipewire
  # https://youtu.be/61wGzIv12Ds?t=181 - "Nixos and Hyprland - Best Match Ever" by Vimjoyer
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.udev.packages = [ pkgs.headsetcontrol ];
}
