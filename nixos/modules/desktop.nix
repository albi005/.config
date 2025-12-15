{
  lib,
  pkgs,
  nixos-2505,
  inputs,
  ...
}: {
  hardware.bluetooth.enable = true; # use with bluetuith
  programs.dconf.enable = true; # gnome settings backend https://nixos.wiki/wiki/Home_Manager#I_cannot_set_GNOME_or_Gtk_themes_via_home-manager
  # programs.firefox.enable = true;
  programs.hyprland.enable = true; # Tiling compositor with the looks
  programs.java.enable = false;
  programs.java.package = pkgs.jdk25;
  programs.kdeconnect.enable = true; # phone link
  programs.seahorse.enable = true; # gnome encryption key and password manager
  programs.wireshark.enable = true; # network protocol analyzer
  security.polkit.enable = true; # gui sudo
  services.gnome.gnome-keyring.enable = true; # security credential store
  services.gvfs.enable = true; # GNOME Virtual file system
  services.printing.enable = true;
  services.upower.enable = true; # required by ags battery widget

  environment.systemPackages = with pkgs; [
    #ags # js based widgets # TODO: Migrate to ags2/astal
    (nixos-2505.ags_1.overrideAttrs (old: {
      # https://github.com/NixOS/nixpkgs/issues/306446#issuecomment-2081540768
      buildInputs = old.buildInputs ++ [libdbusmenu-gtk3];
    }))
    brightnessctl # brightnessctl s 50
    cliphist # wayland clipboard manager with support for multimedia
    dunst # notification daemon https://wiki.hyprland.org/Useful-Utilities/Must-have/#a-notification-daemon
    freeze # code screenshots cli
    elixir # functional programming language
    elixir-ls # used by helix
    erlang
    glib # gsettings
    gparted # disk partitioner
    grimblast # hyprland screenshot program https://github.com/hyprwm/contrib/blob/main/grimblast/grimblast
    hyprpaper # wallpaper daemon
    hyprpicker # color picker
    imagemagick # 'convert' command for images
    libdbusmenu-gtk3 # needed by ags
    libnotify # used by some apps to send notifications
    lxqt.lxqt-policykit # polkit frontend https://wiki.hyprland.org/Useful-Utilities/Must-have/#authentication-agent https://reddit.com/r/NixOS/comments/171mexa/comment/k3rpftn
    nwg-look # gtk theme config gui
    pavucontrol # pulseaudio volume control
    playerctl # media player controller
    rofi # start menu
    waybar # top bar
    wl-clipboard # command-line copy/paste utilities for wayland
  ];

  users.users.albi.packages = with pkgs; [
    alacritty # terminal emulator
    albert # app launcher, like spotlight on macos
    beeper # all your chats in one app
    bluetuith # bluetooth manager tui
    #dbeaver-bin # database client
    desktop-file-utils # needed by something
    ffmpeg-full
    file-roller # archive manager
    #gimp # paint
    gnome-disk-utility # disk manager
    google-chrome
    headsetcontrol # arctis nova 7 battery check
    #imhex # hex editor
    #kitty # terminal emulator
    #krita # paint but actually
    libreoffice
    kdePackages.kruler # screen ruler
    loupe # image viewer
    nemo-with-extensions # file manager
    obsidian # notes
    remmina # remote desktop client
    #sioyek # fancy pdf reader
    sqlitebrowser
    thunderbird # email client
    tinymist # typst language server
    totem # videos
    typst # LaTeX but rust
    # vscode
    # wezterm # terminal emulator
    # wireshark
    wofi-emoji # emoji selector
    inputs.zen-browser.packages."${system}".default # arc but based on firefox
  ];

  home-manager.users.albi = {
    pkgs,
    config,
    ...
  }: {
    # can be overridden to set host specific hyprland config, imported in hyprland.conf, empty by default
    home.file.".config/hypr/host.conf".text = lib.mkDefault "";

    home.file.".config/hypr/hyprpaper.conf".text = let
      wallpaperPath = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/ea1384e183f556a94df85c7aa1dcd411f5a69646/wallpapers/nix-wallpaper-dracula.png";
        sha256 = "sha256-SykeFJXCzkeaxw06np0QkJCK28e0k30PdY8ZDVcQnh4=";
      };
    in ''
      preload = ${wallpaperPath}
      wallpaper = ,${wallpaperPath}
      splash = false
    '';

    # https://github.com/catppuccin/nix/blob/main/modules/home-manager/gtk.nix
    # names changed to lowercase: https://github.com/catppuccin/nix/pull/239
    # https://github.com/catppuccin/gtk/blob/23b52b5/docs/USAGE.md#manual-installation
    # catppuccin/gtk joever: https://github.com/catppuccin/gtk/issues/262
    gtk = {
      enable = true;
      theme = {
        package = pkgs.catppuccin-gtk.override {
          accents = ["green"];
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
    enableDefaultPackages = true;
    packages = with pkgs; [
      cantarell-fonts # GNOME font
      cascadia-code
      corefonts
      nerd-fonts.caskaydia-cove
      nerd-fonts.symbols-only
      roboto
      roboto-slab
      vista-fonts # calibri
    ];
    fontconfig.defaultFonts = {
      sansSerif = ["Cantarell"];
      serif = ["Roboto Slab"];
      monospace = ["Cascadia Code"];
    };
  };

  services.greetd.enable = true;
  programs.regreet = {
    enable = true;
    theme = {
      package = pkgs.catppuccin-gtk.override {
        accents = ["green"];
        size = "compact";
        variant = "mocha";
      };
      name = "catppuccin-mocha-green-compact";
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    cursorTheme = {
      package = pkgs.catppuccin-cursors.mochaLight;
      name = "catppuccin-mocha-light-cursors";
    };
    settings = {
      appearance.greeting_msg = "yo";
      default_session = {
        command = "Hyprland";
        user = "albi";
      };
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

  # Make electron apps use wayland
  # https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.udev.packages = [pkgs.headsetcontrol];
}
