# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

# https://discourse.nixos.org/t/installing-only-a-single-package-from-unstable/5598/4
let
  unstable = import
    (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/nixos-unstable)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports =
    [
      (import "${home-manager}/nixos")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # https://nixos.wiki/wiki/NTFS
  boot.supportedFilesystems = [ "ntfs" ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Budapest";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # home manager stuff
  xsession.enable = true;
  xsession.windowManager.command = "...";

  # Disable GNOME default apps
  services.gnome.core-utilities.enable = false;

  # Configure keymap in X11
  services.xserver = {
    layout = "us,hu";
  };

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "google-chrome";
      TERM = "alacritty";
      TERMINAL = "alacritty";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.albi = {
    isNormalUser = true;
    description = "Albert Ragány-Németh";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      neovim
      spotify
      google-chrome
      alacritty
      gnomeExtensions.clipboard-indicator
      headsetcontrol
      gnomeExtensions.headsetcontrol
      gnomeExtensions.twitchlive-panel
      gnomeExtensions.openweather
      gnome.gnome-disk-utility
      gnome.nautilus
      gnome.totem
    ];
  };

  home-manager.users.albi = import ./home.nix;

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "albi";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    gcc
    nodejs
    lsd
    ripgrep
    unzip
    unstable.nixd
    lua-language-server
    rustup
    dotnet-sdk_8
    # dotnet-sdk_7
    # omnisharp-roslyn
    # msbuild
    ombi
    qbittorrent
    tmux
    python3
    sqlitebrowser
    jetbrains.rider
  ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  services.tailscale.enable = true;

  services.jellyseerr.enable = true;

  services.sonarr.enable = true;
  services.sonarr.group = "media";

  services.radarr.enable = true;
  services.radarr.group = "media";

  services.prowlarr.enable = true;

  services.jellyfin.enable = true;
  services.jellyfin.group = "media";

  services.nginx = {
      enable = true;
      virtualHosts = 
          let listen = [ {
              addr = "100.74.100.33";
              port = 80;
              ssl = false;
          } ];
      in
      {
          "jellyseer.alb1.hu" = {
              locations."/".proxyPass = "http://localhost:5055";
              locations."/".proxyWebsockets = true;
              inherit listen;
          };
          "sonarr.alb1.hu" = {
              locations."/".proxyPass = "http://localhost:8989";
              locations."/".proxyWebsockets = true;
              inherit listen;
          };
          "radarr.alb1.hu" = {
              locations."/".proxyPass = "http://localhost:7878";
              locations."/".proxyWebsockets = true;
              inherit listen;
          };
          "prowlarr.alb1.hu" = {
              locations."/".proxyPass = "http://localhost:9696";
              locations."/".proxyWebsockets = true;
              inherit listen;
          };
          "jellyfin.alb1.hu" = {
              locations."/".proxyPass = "http://localhost:8096";
              locations."/".proxyWebsockets = true;
              inherit listen;
          };
          "torrent.alb1.hu" = {
              locations."/".proxyPass = "http://localhost:10069";
              locations."/".proxyWebsockets = true;
              inherit listen;
          };
      };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };
  networking.interfaces.eno1.wakeOnLan.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
