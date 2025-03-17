{
  pkgs,
  stable,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dotnet.nix
    ../../modules/media.nix
    ../../modules/scanning.nix
  ];

  networking.hostName = "redstone";
  networking.hostId = "d7e8126d"; # needed by zfs
  networking.firewall.allowedTCPPorts = [ 80 ];

  services.actual.enable = true;
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    ensureDatabases = [ "albi" ];
    ensureUsers = [
      {
        name = "albi";
        ensureDBOwnership = true;
      }
    ];
  };

  virtualisation.virtualbox.host.enable = false;
  virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.virtualbox.host.addNetworkInterface = false;

  users.users.albi.packages = with pkgs; [
    jetbrains.clion
    gaphor
    # jetbrains.idea-ultimate
    # jetbrains.phpstorm
    jetbrains.rider
    # jetbrains.ruby-mine # pek-next
    # jetbrains.rust-rover
    # jetbrains.webstorm
    # ruby
    # php
    # https://github.com/NixOS/nixpkgs/issues/358171
    vlc
    staruml
    # prismlauncher
  ];

  environment.systemPackages = [
    # stable.bencodetools
  ];

  systemd.services.cloudflared = {
    description = "cloudflared";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      TimeoutStartSec = 0;
      Type = "notify";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel run --token $CLOUDFLARED_TOKEN";
      Restart = "on-failure";
      RestartSec = "5s";
      EnvironmentFile = "/home/albi/secrets/cloudflared.env";
      User = "cloudflared";
      Group = "cloudflared";
    };
  };
  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };

  services = {
    restic = {
      backups = {
        netherite = {
          backupPrepareCommand = ''
            rm -fr /var/lib/backup
            install -d -m 700 -o root -g root /var/lib/backup
            cd /var/lib/backup
            mkdir -p sus2
            ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/sus2/pings.db ".backup 'sus2/pings.db'"
          '';
          paths = [
            "/home/albi/secrets/"
            "/var/lib/backup/"
          ];
          repository = "rest:http://netherite:31415/redstone";
          passwordFile = "/home/albi/secrets/restic.key";
          initialize = true;
        };
      };
      server = {
        enable = true;
        appendOnly = true;
        extraFlags = [ "--no-auth" ];
        listenAddress = "31415";
      };
    };
  };

  systemd.services.nzxt = {
    description = "NZXT Kraken and Smart Device V1 setup";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.liquidctl}/bin/liquidctl initialize all"
        "${pkgs.liquidctl}/bin/liquidctl --match Kraken set sync color off"
        "${pkgs.liquidctl}/bin/liquidctl --match Smart set led color off"
      ];
    };
  };

  # fix trident z rgb for openrgb https://reddit.com/r/OpenRGB/comments/n8xwju
  boot.kernelParams = [
    "acpi_enforce_resources=lax"
  ];
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    package = pkgs.openrgb-with-all-plugins;
  };

  # https://nixos.wiki/wiki/Nvidia
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    powerManagement.finegrained = false;
    open = false;
  };
}
