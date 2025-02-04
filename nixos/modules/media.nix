{ lib, pkgs, ... }:
{
  imports = [
    ../pkgs/qbittorrent.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-7.0.410"
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
  ];

  # https://openzfs.github.io/openzfs-docs/Getting%20Started/NixOS/index.html
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "zpool" ];

  # wait for zfs mounts before starting media services
  systemd.targets.zfs.before = [
    "qbittorrent.service"
    "jellyfin.service"
    "radarr.service"
    "sonarr.service"
  ];

  users.groups.media.gid = 1337;
  users.groups.media.members = [ "albi" ];

  environment.systemPackages = [
    pkgs.recyclarr
  ];

  services = {
    jellyfin.enable = true;
    jellyfin.group = "media";

    jellyseerr.enable = true;

    sonarr.enable = true;
    sonarr.group = "media";

    radarr.enable = true;
    radarr.group = "media";

    prowlarr.enable = true;

    qbittorrent.enable = true;
    qbittorrent.group = "media";
    qbittorrent.port = 9797;

    nginx = {
      enable = true;
      virtualHosts =
        let
          tailscaleToLocalhost = port: {
            locations."/".proxyPass = "http://localhost:${builtins.toString port}";
            locations."/".proxyWebsockets = true;
            listen = [
              {
                addr = "100.69.0.4";
                port = 80;
                ssl = false;
              }
            ];
          };
        in
        {
          "jellyfin.alb1.hu" = tailscaleToLocalhost 8096;
          "jellyseer.alb1.hu" = tailscaleToLocalhost 5055;
          "sonarr.alb1.hu" = tailscaleToLocalhost 8989;
          "radarr.alb1.hu" = tailscaleToLocalhost 7878;
          "prowlarr.alb1.hu" = tailscaleToLocalhost 9696;
          "torrent.alb1.hu" = tailscaleToLocalhost 9797;
        };
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = [ "127.0.0.1:8191:8191" ];
      };
    };
  };
}
