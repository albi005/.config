{
  lib,
  pkgs,
  nixos-2505,
  inputs,
  nixos-unstable,
  config,
  ...
}:
let
  nixos-config = config;
in
{
  hardware.bluetooth.enable = true; # use with bluetuith
  programs.dconf.enable = true; # gnome settings backend https://nixos.wiki/wiki/Home_Manager#I_cannot_set_GNOME_or_Gtk_themes_via_home-manager
  # programs.firefox.enable = true;
  programs.hyprland.enable = true; # Tiling compositor with the looks
  programs.hyprland.withUWSM = true; # UWSM is the thing that provides the .desktop that is started by a display manager. UWSM handles session stuff https://wiki.hypr.land/Useful-Utilities/Systemd-start/#uwsm
  services.displayManager.ly.enable = true;
  # services.desktopManager.plasma6.enable = true; # enable if you need x11. switch using login manager after exiting hyprland
  programs.java.enable = true;
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
      buildInputs = old.buildInputs ++ [ libdbusmenu-gtk3 ];
    }))
    brightnessctl # brightnessctl s 50
    libcanberra-gtk3 # used by alacritty to play bell sound
    cliphist # wayland clipboard manager with support for multimedia
    dunst # notification daemon https://wiki.hyprland.org/Useful-Utilities/Must-have/#a-notification-daemon
    freeze # code screenshots cli
    # elixir # functional programming language
    # erlang
    glib # gsettings
    gparted # disk partitioner
    grimblast # hyprland screenshot program https://github.com/hyprwm/contrib/blob/main/grimblast/grimblast
    hyprls
    hyprpaper # wallpaper daemon
    hyprpicker # color picker
    imagemagick # 'convert' command for images
    libdbusmenu-gtk3 # needed by ags
    libnotify # used by some apps to send notifications
    lxqt.lxqt-policykit # polkit frontend https://wiki.hyprland.org/Useful-Utilities/Must-have/#authentication-agent https://reddit.com/r/NixOS/comments/171mexa/comment/k3rpftn
    nwg-look # gtk theme config gui
    pavucontrol # pulseaudio volume control, audio settings, headset/output configuration
    playerctl # media player controller
    rofi # clipboard
    waybar # top bar
    wl-clipboard # command-line copy/paste utilities for wayland

    gnome-tweaks
    dconf-editor
    quickshell
    kdePackages.qtdeclarative # qmlls
  ];

  users.users.albi.packages = with pkgs; [
    alacritty # terminal emulator
    albert # app launcher, like spotlight on macos
    beeper # all your chats in one app
    bluetuith # bluetooth manager tui
    #dbeaver-bin # database client
    desktop-file-utils # needed by something
    # ffmpeg-full
    file-roller # archive manager
    #gimp # paint
    gnome-disk-utility # disk manager
    # google-chrome
    headsetcontrol # arctis nova 7 battery check
    #imhex # hex editor
    #kitty # terminal emulator
    #krita # paint but actually
    # libreoffice
    kdePackages.kruler # screen ruler
    loupe # image viewer
    nemo-with-extensions # file manager
    obsidian # notes
    remmina # remote desktop client
    (
      if config.networking.hostName != "redstone" then
        sioyek # fancy pdf reader
      else
        # HACK: fix Qt OpenGL context creation on Wayland
        # idk why it's only brokie on redstone
        (pkgs.symlinkJoin {
          name = "sioyek-wrapped";
          paths = [ nixos-unstable.sioyek ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/sioyek \
              --set QT_QPA_PLATFORM xcb \
              --prefix LD_LIBRARY_PATH : ${
                lib.makeLibraryPath [
                  pkgs.libGL
                  pkgs.libglvnd
                ]
              }
          '';
        })
    )
    # sqlitebrowser
    nixos-2505.thunderbird # email client
    # tinymist # typst language server
    totem # videos
    # typst # LaTeX but rust
    # vscode
    wezterm # terminal emulator
    # wireshark
    wofi-emoji # emoji selector
    inputs.nur.legacyPackages."${stdenv.hostPlatform.system}".repos.Ev357.helium # chromium fork
    # zed-editor
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".default # arc but based on firefox
  ];

  # services.desktopManager.gnome.enable = true;
  # services.displayManager.gdm.enable = true;

  home-manager.users.albi =
    {
      pkgs,
      config,
      ...
    }:
    {
      programs.fuzzel.enable = true;

      # can be overridden to set host specific hyprland config, imported in hyprland.conf, empty by default
      home.file.".config/hypr/host.lua".text = lib.mkDefault "";

      # home.file.".config/hypr/hyprpaper.conf".text =
      #   let
      #     wallpaperPath = pkgs.fetchurl {
      #       url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/ea1384e183f556a94df85c7aa1dcd411f5a69646/wallpapers/nix-wallpaper-dracula.png";
      #       sha256 = "sha256-SykeFJXCzkeaxw06np0QkJCK28e0k30PdY8ZDVcQnh4=";
      #     };
      #   in
      #   ''
      #     wallpaper {
      #       monitor =
      #       path = ${wallpaperPath}
      #     }
      #     splash = false
      #   '';

      # https://wiki.hypr.land/Configuring/Start/#autocompletions
      home.file.".config/.luarc.json".text = ''
        {
          "workspace": {
            "library": [
              "${nixos-config.programs.hyprland.package}/share/hypr/stubs"
            ]
          }
        }
      '';

      # https://github.com/catppuccin/nix/blob/main/modules/home-manager/gtk.nix
      # names changed to lowercase: https://github.com/catppuccin/nix/pull/239
      # https://github.com/catppuccin/gtk/blob/23b52b5/docs/USAGE.md#manual-installation
      # catppuccin/gtk joever: https://github.com/catppuccin/gtk/issues/262
      # gtk = {
      #   enable = false;

      #   # https://nixos.org/manual/nixos/stable/#sec-gnome-icons-and-gtk-themes
      #   theme = {
      #     package = pkgs.catppuccin-gtk.override {
      #       accents = [ "green" ];
      #       size = "compact";
      #       variant = "mocha";
      #     };
      #     name = "catppuccin-mocha-green-compact";
      #   };
      #   iconTheme = {
      #     package = pkgs.adwaita-icon-theme;
      #     name = "Adwaita";
      #   };
      #   gtk4.theme = null;
      # };

      # home.pointerCursor = {
      #   # gtk.enable = true;
      #   # x11.enable = true;
      #   package = pkgs.catppuccin-cursors.mochaLight;
      #   name = "catppuccin-mocha-light-cursors";
      #   size = 24;
      # };
    };

  # https://nix-community.github.io/stylix/configuration.html
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  stylix.polarity = "dark";
  stylix.fonts = {
    serif = {
      package = pkgs.roboto-serif;
      name = "Roboto Serif";
    };
    sansSerif = {
      package = pkgs.cantarell-fonts;
      name = "Cantarell";
    };
    monospace = {
      package = pkgs.cascadia-code;
      name = "Cascadia Code";
    };
  };
  stylix.cursor = {
    package = pkgs.catppuccin-cursors.mochaLight;
    name = "catppuccin-mocha-light-cursors";
    size = 24;
  };
  stylix.image = config.lib.stylix.pixel "base00";
  home-manager.sharedModules = [
    {
      stylix.targets.hyprpaper.enable = true;
      services.hyprpaper.enable = true;
    }
  ];
  # qt.enable = false;
  # qt.style = "adwaita-dark";
  # qt.platformTheme = "gnome";

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
    # fontconfig.defaultFonts = {
    #   sansSerif = [ "Cantarell" ];
    #   serif = [ "Roboto Slab" ];
    #   monospace = [ "Cascadia Code" ];
    # };
  };

  # services.greetd.enable = false;
  programs.regreet = {
    # enable = false;
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

  services.udev.packages = [ pkgs.headsetcontrol ];

  hardware.i2c.enable = true;
}
