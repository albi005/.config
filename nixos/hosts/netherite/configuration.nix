{
  config,
  pkgs,
  inputs,
  stable,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../pkgs/qbittorrent.nix
    ../../modules/dotnet.nix
  ];

  virtualisation.docker.enable = true;

  # needed by schpincer
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
  };

  services.postgresql = {
    authentication = '''';
    enable = true;
    enableTCPIP = true;
    ensureDatabases = [ "startsch" "albi" ];
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
  };
  users = {
    users.startsch = {
      group = "startsch";
      uid = 2001;
      isSystemUser = true;
    };
    groups.startsch.gid = 2001;
  };

  services.teamviewer.enable = true;
  services.statusApi.enable = true;
  services.statusApi.host = "netherite";

  networking.hostName = "netherite";

  environment.systemPackages = with pkgs; [
    vlc
    jdk11
    gaphor
    uppaal
  ];

  users.users.albi.packages = with pkgs; [
    jetbrains.idea-ultimate
    stable.jetbrains.rider
    jetbrains.webstorm
    jetbrains.phpstorm
    jetbrains.rust-rover
    prismlauncher # minecraft launcher
    devcontainer # docker based dev envs
    #cura # https://discourse.nixos.org/t/issue-building-nixos-due-to-sip-package/48702/2
    php # authsch
  ];

  systemd.services.cloudflared = {
    description = "cloudflared";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
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
  users.groups.cloudflared = { };

  services.strongswan.enable = true;

  services.restic = {
    server = {
      enable = true;
      appendOnly = true;
      extraFlags = [ "--no-auth" ];
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
}
