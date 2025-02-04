{ pkgs, stable, lib, ... }:
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
  networking.firewall.allowedTCPPorts = [80];

  services.teamviewer.enable = true;
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

  users.users.albi.packages = with pkgs; [
    # jetbrains.clion
    jetbrains.idea-ultimate
    # jetbrains.phpstorm
    # jetbrains.ruby-mine # pek-next
    # jetbrains.rust-rover
    jetbrains.webstorm
    # ruby
    # php
    # https://github.com/NixOS/nixpkgs/issues/358171
    (jetbrains.rider.overrideAttrs (attrs: {
      postInstall =
        (attrs.postInstall or "")
        + lib.optionalString (stdenv.hostPlatform.isLinux) ''
          (
            cd $out/rider

            ls -d $PWD/plugins/cidr-debugger-plugin/bin/lldb/linux/*/lib/python3.8/lib-dynload/* |
            xargs patchelf \
              --replace-needed libssl.so.10 libssl.so \
              --replace-needed libcrypto.so.10 libcrypto.so \
              --replace-needed libcrypt.so.1 libcrypt.so

            for dir in lib/ReSharperHost/linux-*; do
              rm -rf $dir/dotnet
              ln -s ${dotnet-sdk_7.unwrapped}/share/dotnet $dir/dotnet 
            done
          )
        '';
    }))
    vlc
    prismlauncher
  ];

  environment.systemPackages = [
    stable.bencodetools
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
