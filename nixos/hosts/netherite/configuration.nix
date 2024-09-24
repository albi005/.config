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
  # virtualisation.docker.rootless.enable = true;
  # virtualisation.docker.rootless.setSocketVariable = true;

  services.statusApi.enable = true;
  services.statusApi.host = "netherite";

  networking.hostName = "netherite";

  hardware.sane.enable = true; # scanner daemon
  users.users.albi.extraGroups = [
    "scanner"
    "lp"
  ];

  environment.systemPackages = with pkgs; [
    vlc
  ];

  users.users.albi.packages = with pkgs; [
    jetbrains.idea-ultimate
    stable.jetbrains.rider
    jetbrains.webstorm
    prismlauncher # minecraft launcher
    jetbrains-toolbox
    naps2 # scanner gui
    devcontainer # docker based dev envs
    #cura # https://discourse.nixos.org/t/issue-building-nixos-due-to-sip-package/48702/2
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
