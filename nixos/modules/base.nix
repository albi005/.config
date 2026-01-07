{
  lib,
  pkgs,
  config,
  inputs,
  nixos-unstable,
  ...
}: {
  imports = [
    ./status.nix
    ./neovim.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # https://wiki.nixos.org/wiki/Binary_Cache#Using_a_binary_cache
      substituters = [
        "https://nix-community.cachix.org"
        "https://nvf.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nvf.cachix.org-1:GMQWiUhZ6ux9D5CvFFMwnc2nFrUHTeGaXRlVBXo+naI="
      ];
    };
  };

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
  boot.supportedFilesystems = ["ntfs"];

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
      inputs.git-leave.packages."${system}".default # searches for uncommited/unpushed git changes
      inputs.wakatime-ls.packages."${system}".default # coding-time tracker language-server for helix
      bat # cat/less with highlighting
      bottom # task manager, `btm`
      bun # js but based and fast af
      calc # short for calculator
      cloc # Count Lines Of Code
      cmatrix # Matrix like effect in your terminal
      corepack # pnpm pnpx yarn yarnpkg
      cmctl # Kubernetes cert-manager manager
      dig # dns tools
      dua # 🐐 Disk Usage Analyzer tui, `dua i`
      exiftool # image metadata reader
      fastfetch # neoneofetch
      fd # find file by name
      file # file info
      gcc
      nixos-unstable.gemini-cli # google's vibe-slop cli
      gh # github cli, `gh auth setup-git`
      glow # .md reader tui
      gnumake # `make`
      go
      gopls
      gotools
      helix # neovim but rust (actually goated)
      inetutils # dnsdomainname ftp hostname ifconfig logger ping ping6 rcp rexec rlogin rsh talk telnet tftp traceroute whois
      iperf # speed test between hosts
      jq # command-line JSON processor
      k3d # instant Kubernetes clusters `k3d cluster create mycluster --image rancher/k3s:v1.29.6-k3s1`
      k9s # Kubernetes TUI
      kubecolor # kubectl but with colors
      kubectl # Kubernetes CLI
      kubectl-cnpg # cloud native postgres manager cli, `kubectl cnpg`
      kubelogin-oidc # for auth to KSZK Kubernetes cluster, `kubectl oidc-login`
      kubernetes-helm # kubernetes package manager
      lsd # ls but rust
      maven # java slop "build system", `mvn`
      netscanner # nmap tui
      nil # nix ls: refactorings
      nixd # nix ls: code completion and documentation for packages and options, even shows package versions in inlay hints
      nixfmt # official nix formatter
      nmap # hackerman, `sudo nmap 192.168.0.0/24`
      nodejs # slop machine
      onefetch # neofetch for git
      pstree # processs tree
      python3 # even slower slop machine
      restic # backups
      ripgrep # rg, find text in files
      rustic # restic but rust
      rustup
      scryer-prolog # Prolog implementation in Rust
      sl # train
      smartmontools # ssd health
      sqlcmd # sql server
      swi-prolog-gui
      systemctl-tui
      tcpdump
      trippy # tracecroute tui
      typescript # duct tape for slopscript
      unzip
      wget
      xclip
      xz
      yaml-language-server # for helix
      yarn # yet another slopscript package manager
      yazi # file explorer tui
      yt-dlp
      zip # `zip zip.zip *.zip`
      zoxide # cd but rust
    ];
  };

  programs.direnv.enable = true;
  programs.git.enable = true;
  # programs.java.enable = true;
  # programs.java.package = pkgs.jdk21;
  programs.nix-ld.enable = true; # enables running dynamic binaries that haven't been patched for nixos
  programs.nix-ld.package = pkgs.nix-ld;
  services.tailscale.enable = true; # p2p vpn

  systemd.services.tailscaled.before = ["nginx.service"]; # make nginx wait for tailscale

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
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

  # don't give up because of missing disks at startup
  systemd.enableEmergencyMode = false;

  users.users.albi = {
    isNormalUser = true;
    description = "Albert Ragány-Németh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "vboxusers"
      "wireshark"
    ];
    packages = [];
  };

  home-manager.users.albi = {
    config,
    pkgs,
    ...
  }: {
    home.sessionPath = ["${config.home.homeDirectory}/.dotnet/tools"];

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
        dw = "dotnet watch";
        e = "python3 $HOME/.config/scripts/print-env.py";
        ed = "nvim";
        f = "fastfetch";
        h = "curl -v -o /dev/null";
        l = "lsd -al --group-directories-first --date '+%Y.%m.%d %H:%M'";
        nano = "nvim";
        ports = "sudo netstat -tulpn";
        rb = "sudo nixos-rebuild switch --flake /home/albi/.config/nixos"; # rebuild desktop; use versions from lock file
        rbs = "rb --recreate-lock-file --no-write-lock-file"; # rebuild server; use latest version of everything without updating the lock file
        rsync = "rsync --progress";
        st = "systemctl-tui";
        sus = "systemctl suspend";
        td = "tree --depth";
        tree = "l --tree --group-directories-first";
        try = "nix-shell -p";
        update = "nix flake update --flake /home/albi/.config/nixos";
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
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

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
    flake = "path:${config.users.users.albi.home}/.config/nixos#${config.networking.hostName}";
    flags = [
      "--recreate-lock-file" # update everything
      # "--no-write-lock-file"
      "--print-build-logs"
    ];
    allowReboot = false; # TODO: REENABLE AFTER STARTSCH HAS BEEN FIXED
    persistent = false; # don't run at startup
  };

  # allow root to access the git repo of the nix flake
  # fixes "dubious ownership" error when running autoUpgrade
  # if you have a better fix send me an email <3
  # btw this only happens when the working tree is clean
  programs.git.config.safe.directory = "/home/albi/.config/.git";

  nix.gc = {
    automatic = true;
    dates = "04:11";
    options = "--delete-older-than 30d";
    persistent = false;
  };

  services.journald.extraConfig = ''
    SystemMaxUse=300M
  '';

  # blank tty after 60 seconds
  boot.kernelParams = ["consoleblank=60"];

  # DON'T TOUCH
  system.stateVersion = "23.05";
}
