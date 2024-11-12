{ pkgs, stable, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/media.nix
    ../../modules/dotnet.nix
  ];

  networking.hostName = "redstone";
  networking.hostId = "d7e8126d"; # needed by zfs

  programs.java.package = pkgs.jdk11;

  services.teamviewer.enable = true;

  users.users.albi.packages = with pkgs; [
    jetbrains.clion
    jetbrains.idea-ultimate
    jetbrains.rider
    vlc
    prismlauncher
  ];

  environment.systemPackages = [
    stable.bencodetools
  ];

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
