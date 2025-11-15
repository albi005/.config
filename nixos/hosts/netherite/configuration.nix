{
  config,
  pkgs,
  inputs,
  stable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dotnet.nix
    ../../modules/dev.nix
  ];

  services.teamviewer.enable = true;
  services.mongodb.enable = true;

  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.startx.enable = true;

  virtualisation.docker.enable = true;
  # virtualisation.virtualbox.host.enable = true; # disable docker before enabling this
  # virtualisation.vmware.host.enable = true;
  # virtualisation.virtualbox.host.enableKvm = true;
  # virtualisation.virtualbox.host.addNetworkInterface = false;

  # programs.adb.enable = true;

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = ["albi"];
    ensureUsers = [
      {
        name = "albi";
        ensurePermissions = {
          "albi.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.postgresql = {
    authentication = '''';
    enable = true;
    enableTCPIP = true;
    ensureDatabases = [
      "startsch"
      "albi"
    ];
    ensureUsers = [
      {
        name = "startsch";
        ensureDBOwnership = true;
      }
      {
        name = "albi";
        ensureDBOwnership = true;
      }
    ];
    package = pkgs.postgresql_17_jit;
  };
  users = {
    users.startsch = {
      group = "startsch";
      uid = 2001;
      isSystemUser = true;
    };
    groups.startsch.gid = 2001;
  };

  # services.teamviewer.enable = true;
  services.statusApi.enable = true;
  services.statusApi.host = "netherite";

  networking.hostName = "netherite";

  environment.systemPackages = with pkgs; [
    cachix
  ];

  users.users.albi.packages = with pkgs; [
    lens # K8s "IDE"
    jetbrains.idea-ultimate
    jetbrains.rider
    android-studio
    jetbrains.webstorm
    jetbrains.phpstorm
    # jetbrains.rust-rover
    # jetbrains.clion
    # prismlauncher # minecraft launcher
    # devcontainer # docker based dev envs
    #cura # https://discourse.nixos.org/t/issue-building-nixos-due-to-sip-package/48702/2
    # php # authsch
    prisma
    prisma-engines
  ];

  systemd.services.cloudflared = {
    description = "cloudflared";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      TimeoutStartSec = 0;
      Type = "notify";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel run";
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
  users.groups.cloudflared = {};

  services.tailscale.useRoutingFeatures = "both";

  services.restic = {
    server = {
      enable = true;
      appendOnly = true;
      extraFlags = ["--no-auth"];
      listenAddress = "31415";
    };
    # backups = {
    #     local = {
    #         paths = [
    #             "/home/albi/secrets/"
    #             "/var/lib/backup/"
    #             "/var/lib/couchdb/.shards/"
    #             "/var/lib/couchdb/shards/"
    #             "/var/lib/couchdb/*.couch"
    #             "/var/lib/couchdb/local.ini"
    #         ];
    #         repository = "rest:http://netherite:31415/iron";
    #         passwordFile = "/home/albi/secrets/restic.key";
    #         initialize = true;
    #     };
    # };
  };

  services.nginx = {
    enable = true;
    virtualHosts = let
      tailscaleToLocalhost = port: {
        locations."/".proxyPass = "http://localhost:${builtins.toString port}";
        locations."/".proxyWebsockets = true;
        listen = [
          {
            addr = "100.69.0.1";
            port = 80;
            ssl = false;
          }
        ];
      };
    in {
      "netherite" = tailscaleToLocalhost 3006;
    };
  };
}
