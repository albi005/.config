{ lib, pkgs, ... }:
{
  imports = [
    ./neovim.nix
    ./status.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing (scroll down)
  boot.loader = {
    systemd-boot = {
      # Use systemd-boot by default
      enable = lib.mkDefault true;

      # Fix virtual console being blurry
      # https://reddit.com/r/archlinux/comments/oe8u2q/fix_tty_resolution_with_nvidia_driver/
      consoleMode = "max";
    };

    # Set to false when running on garbage
    # https://nixos.wiki/wiki/Bootloader#Installing_x86_64_NixOS_on_IA-32_UEFI
    efi.canTouchEfiVariables = lib.mkDefault true;

    # Update in host config as necessary
    grub.device = lib.mkDefault "/dev/sda";
  };

  # https://nixos.wiki/wiki/NTFS
  boot.supportedFilesystems = [ "ntfs" ];

  # https://nixos.wiki/wiki/Nixos-generate-config
  fileSystems."/".options = [
    "noatime"
    "nodiratime"
    "discard"
  ];

  environment = {
    # /etc/profile sources /nix/store/*-set-environment
    variables = {
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    systemPackages = with pkgs; [
      bottom
      calc
      cava # tui audio visualizer
      cloc # Count Lines Of Code
      cmatrix # Matrix like effect in your terminal
      dig # dns tools
      dua # Disk Usage Analyzer tui
      exiftool
      fastfetch
      fd # find file by name
      file # file info
      gcc
      git
      gh
      glow # .md tui
      gnumake # make
      go
      gopls
      gotools
      inetutils
      iperf
      jq # command-line JSON processor
      lsd
      lua-language-server
      mono
      netscanner # nmap tui
      nil
      nixd
      nixfmt-rfc-style
      nmap
      nodejs
      onefetch # neofetch for git
      pstree # processs tree
      python3
      restic # backups
      ripgrep # rg, find text in files
      rustup
      sl # train
      smartmontools
      sqlcmd # sql server
      systemctl-tui
      tcpdump
      typescript
      unzip
      wget
      xclip
      xz
      yarn
      yazi # file manager tui
      yt-dlp
      zip
      zoxide # fancy cd
    ];
  };

  programs.nix-ld.enable = true; # enables running unpatched dynamic binaries
  programs.nix-ld.package = pkgs.nix-ld-rs;
  programs.java.enable = true;
  services.tailscale.enable = true; # p2p vpn

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
    };

    # Cloudflare DNS
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  # https://discourse.nixos.org/t/19963/2
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  programs.direnv.enable = true;

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      catppuccin
    ];
    extraConfig = ''
      set-option -ga terminal-overrides ',alacritty:Tc'

      #https://wezfurlong.org/wezterm/shell-integration.html#user-vars
      set -g allow-passthrough on
    '';
  };

  # Ignore missing disks
  systemd.enableEmergencyMode = false;

  users.users.albi = {
    isNormalUser = true;
    description = "Albert Ragány-Németh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
    ];
    packages = [ ];
  };

  home-manager.users.albi =
    { config, pkgs, ... }:
    {
      home.sessionPath = [ "${config.home.homeDirectory}/.dotnet/tools" ];

      programs.bash = {
        enable = true;

        shellAliases = {
          b = "headsetcontrol -b";
          c = "clear";
          c-bash = "nvim ~/.profile && source ~/.profile";
          c-hyprland = "PREV_PWD=$PWD; cd ~/.config/hypr; nvim hyprland.conf; cd $PREV_PWD";
          c-nix = "PREV_PWD=$PWD; cd ~/.config/nixos; v; cd $PREV_PWD";
          c-scripts = "PREV_PWD=$PWD; cd ~/.config/scripts; v; cd $PREV_PWD";
          c-vim = "PREV_PWD=$PWD; cd ~/.config/nvim; v; cd $PREV_PWD";
          cfg = "cd ~/.config";
          cl = "c && l";
          colors = "curl -s https://gist.githubusercontent.com/grhbit/db6c5654fa976be33808b8b33a6eb861/raw/1875ff9b84a014214d0ce9d922654bb34001198e/24-bit-color.sh | bash";
          e = "python3 $HOME/.config/scripts/print-env.py";
          f = "fastfetch";
          l = "lsd -al --group-directories-first --date '+%Y.%m.%d %H:%M'";
          ports = "sudo netstat -tulpn";
          rb = "sudo nixos-rebuild switch --flake /home/albi/.config/nixos"; # rebuild desktop, use versions from lock file
          rbs = "rb --recreate-lock-file --no-write-lock-file"; # rebuild server, use latest version of everything without updating the lock file
          rsync = "rsync --progress";
          st = "systemctl-tui";
          tree = "l --tree --group-directories-first";
          try = "nix-shell -p ";
          update = "nix flake update /home/albi/.config/nixos";
          v = "nvim .";
        };

        bashrcExtra = ''
          export PATH="$PATH:/home/albi/.dotnet/tools:/home/albi/.npm-packages/bin";
          export PS1="\\[\\033[01;1m\\]\\u@\\h \\[\\033[01;33m\\]\\w \\[\\033[01;35m\\]\$ \\[\\033[00m\\]";
          export NODE_PATH=~/.npm-packages/lib/node_modules;

          # https://yazi-rs.github.io/docs/quick-start#shell-wrapper
          function y() {
              local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                  builtin cd -- "$cwd"
              fi
              rm -f -- "$tmp"
          }

          # https://github.com/ajeetdsouza/zoxide#installation
          eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
        '';
      };

      home.file.".npmrc".text = ''
        prefix=~/.npm-packages
      '';

      # behind tailscale, don't care
      home.file.".wakatime.cfg".text = ''
        [settings]
        api_url = http://waka.alb1.hu/api
        api_key = b9753890-9f75-498f-9155-d19f2190de78
      '';

      programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        shellWrapperName = "y";

        settings = {
          manager = {
            show_hidden = true;
            sort_dir_first = true;
          };
        };
      };

      # DONT'T TOUCH
      home.stateVersion = "23.05";
    };

  services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
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

  system.autoUpgrade = {
    enable = true;
    dates = "03:33";
    flake = "/home/albi/.config/nixos";
    flags = [
      "--recreate-lock-file" # update everything
      "--no-write-lock-file"
      "--print-build-logs"
    ];
    allowReboot = true;
  };

  nix.gc = {
    automatic = true;
    dates = "04:11";
    options = "--delete-older-than 30d";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=100M
  '';

  # blank tty after 60 seconds
  boot.kernelParams = [ "consoleblank=60" ];

  # DON'T TOUCH
  system.stateVersion = "23.05";
}
