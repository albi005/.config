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
  # programs.java.package = pkgs.jdk25;
  programs.kdeconnect.enable = true; # phone link
  programs.seahorse.enable = true; # gnome encryption key and password manager
  programs.wireshark.enable = true; # network protocol analyzer
  security.polkit.enable = true; # gui sudo
  services.gnome.gnome-keyring.enable = true; # security credential store
  services.comin.desktop.enable = true; # desktop notifications on comin deploys
  services.gvfs.enable = true; # GNOME Virtual file system
  services.printing.enable = true;
  services.upower.enable = true; # required by ags battery widget

  # fix `nixos-rebuild switch` restarting the desktop session
  systemd.user.services."wayland-session-bindpid@" = {
    overrideStrategy = "asDropin";
    restartIfChanged = false;
  };

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

    # gnome-tweaks
    dconf-editor
    quickshell
    kdePackages.qtdeclarative # qmlls
    vscode
  ];

  users.users.albi.packages = with pkgs; [
    alacritty # terminal emulator
    albert # app launcher, like spotlight on macos
    appimage-run # `appimage-run Fortnite.AppImage`
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
    kdePackages.kolourpaint # ms paint but linux
    loupe # image viewer
    nemo-with-extensions # file manager
    obsidian # notes
    qalculate-qt # 50years/1000000 to minute
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
    # zed-editor
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".default # arc but based on firefox
    inputs.helium-browser.packages."${stdenv.hostPlatform.system}".default # chromium fork

    # Interactive GitOps deploy script: pick flake input(s) with gum, update
    # flake.lock in a clean temp clone, open a PR, optionally pre-build & copy
    # closures to target hosts (zero sudo on iron), merge, and trigger comin.
    (pkgs.writeShellScriptBin "deploy" ''
      set -euo pipefail

      git="${pkgs.git}/bin/git"
      gh="${pkgs.gh}/bin/gh"
      gum="${pkgs.gum}/bin/gum"
      jq="${pkgs.jq}/bin/jq"
      nix="${config.nix.package}/bin/nix"
      ssh="${config.programs.ssh.package}/bin/ssh"

      tmp="$(mktemp -d -t deploy-config-XXXXXX)"
      trap 'rm -rf "$tmp"' EXIT

      echo "Cloning albi005/.config (main)..."
      "$git" clone --quiet --depth=1 --branch main https://github.com/albi005/.config.git "$tmp"
      cd "$tmp"

      if [[ $# -gt 0 ]]; then
        inputs=("$@")
      else
        mapfile -t available < <("$jq" -r '.nodes.root.inputs | keys[]' nixos/flake.lock)
        mapfile -t inputs < <("$gum" choose --no-limit --height=20 \
          --header "Select flake input(s) to update (Space to toggle, Enter to confirm)" \
          "''${available[@]}")
      fi

      if [[ ''${#inputs[@]} -eq 0 ]]; then
        echo "No inputs selected."
        exit 0
      fi

      old_lock="$(cat nixos/flake.lock)"
      echo "Updating flake input(s): ''${inputs[*]}..."
      "$nix" flake update --flake ./nixos "''${inputs[@]}"

      if "$git" diff --quiet nixos/flake.lock; then
        echo "Already up to date (nixos/flake.lock unchanged)."
        exit 0
      fi

      # Build a concise old -> new rev summary for the PR body.
      summary=""
      for inp in "''${inputs[@]}"; do
        old_rev="$(printf '%s' "$old_lock" | "$jq" -r --arg k "$inp" '.nodes[.nodes.root.inputs[$k]].locked | (.rev // .narHash // "?")' | cut -c1-7)"
        new_rev="$("$jq" -r --arg k "$inp" '.nodes[.nodes.root.inputs[$k]].locked | (.rev // .narHash // "?")' nixos/flake.lock | cut -c1-7)"
        if [[ "$old_rev" != "$new_rev" ]]; then
          summary+="- \`$inp\`: \`$old_rev\` -> \`$new_rev\`"$'\n'
        fi
      done
      echo ""
      printf '%s\n' "$summary"

      slug="$(IFS=-; echo "''${inputs[*]}")"
      branch="update/''${slug}-$(date +%Y%m%d-%H%M%S)"
      title="Update ''${inputs[*]}"

      "$git" checkout -q -b "$branch"
      "$git" add nixos/flake.lock
      "$git" commit -q -m "$title"
      "$git" push -q -u origin "$branch"

      pr_url="$("$gh" pr create --base main --head "$branch" --title "$title" --body "$(printf 'Updated flake input(s):\n\n%s' "$summary")")"
      pr_num="''${pr_url##*/}"
      echo "Opened PR #$pr_num: $pr_url"

      local_host="$(hostname)"
      host_choices=("iron")
      if [[ "$local_host" != "iron" ]]; then
        host_choices+=("$local_host")
      fi

      mapfile -t prebuild_hosts < <("$gum" choose --no-limit --selected=iron \
        --header "Pre-build & push closure before merging? (Space to toggle, Enter to continue)" \
        "''${host_choices[@]}" || true)

      for host in "''${prebuild_hosts[@]}"; do
        echo "Building nixosConfigurations.$host..."
        out="$("$nix" build --no-link --print-out-paths "./nixos#nixosConfigurations.$host.config.system.build.toplevel")"
        if [[ "$host" != "$local_host" ]]; then
          echo "Copying closure to $host..."
          "$nix" copy --to "ssh://albi@$host" --substitute-on-destination "$out"
        fi
      done

      if "$gum" confirm "Merge PR #$pr_num and trigger comin fetch?"; then
        "$gh" pr merge "$pr_num" --squash --delete-branch
        for host in "''${prebuild_hosts[@]}"; do
          if [[ "$host" == "$local_host" ]]; then
            comin fetch || true
          else
            "$ssh" "albi@$host" comin fetch || true
          fi
        done
        echo "Merged PR #$pr_num and triggered comin."
      else
        echo "Left PR #$pr_num open: $pr_url"
      fi
    '')
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
  # avoid the stylix gtksourceview overlay, which changes gtksourceview4's
  # output hash and cascades into cache misses (inkscape, catppuccin-cursors)
  stylix.targets.gtksourceview.enable = false;
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
