{ pkgs, config, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../pkgs/qbittorrent.nix
  ];

  networking.hostName = "iron";

  boot.loader.systemd-boot.enable = false;

  services.statusApi.enable = true;
  services.statusApi.host = "100.69.0.2";

  virtualisation.docker.enable = true;

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://p.alb1.hu";
      SIGNUPS_ALLOWED = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 10003;
    };
  };

  services.couchdb = {
      package = inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.couchdb3;
      enable = true;
      port = 10004;
  };

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

  systemd.services.wakapi = {
    # https://github.com/muety/wakapi/blob/master/etc/wakapi.service
    description = "Wakapi";
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wakapi}/bin/wakapi";
      WorkingDirectory = "/var/lib/wakapi";
      StateDirectory = "wakapi";
      StateDirectoryMode = "0700";
      User = "wakapi";
      Group = "wakapi";

      PrivateTmp = "true";
      PrivateUsers = "true";
      NoNewPrivileges = "true";
      ProtectSystem = "full";
      ProtectHome = "true";
      ProtectKernelTunables = "true";
      ProtectKernelModules = "true";
      ProtectKernelLogs = "true";
      ProtectControlGroups = "true";
      PrivateDevices = "true";
      CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
      ProtectClock = "true";
      RestrictSUIDSGID = "true";
      ProtectHostname = "true";
      ProtectProc = "invisible";
    };
  };
  users.users.wakapi = {
    group = "wakapi";
    isSystemUser = true;
  };
  users.groups.wakapi = { };

  # https://github.com/vogler/free-games-claimer
  # sudo docker run --rm -it -p 6080:6080 -v fgc:/fgc/data --pull=always ghcr.io/vogler/free-games-claimer node epic-games
  # noVNC at http://iron:6080
  # services.cron = {
  #     enable = true;
  #     systemCronJobs = [
  #         "0 3 * * * docker run --rm -it -p 6080:6080 -v fgc:/fgc/data --pull=always ghcr.io/vogler/free-games-claimer node epic-games"
  #     ];
  # };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      alb1 = {
        image = "alb1";
        ports = [ "10001:8080" ];
      };
      menza = {
        image = "menza";
        volumes = [ "/home/albi/www/Menza:/data" ];
        environment = {
          ConnectionStrings__Database = "Data Source=/data/menza.db";
          Firebase__ServiceAccount = "/data/service-account.json";
        };
        environmentFiles = [ /home/albi/secrets/menza.env ];
        ports = [ "10002:8080" ];
      };
      dishelps = {
        image = "dishelps";
        volumes = [ "/home/albi/www/DisHelps:/data" ];
        environment = {
          ConnectionStrings__Database = "Data Source=/data/dishelps.db";
        };
        ports = [ "10005:8080" ];
      };
      keletikuria = {
        image = "keletikuria";
        volumes = [ "/home/albi/www/KeletiKuria:/data" ];
        environment = {
          ConnectionStrings__Database = "Data Source=/data/keletikuria.db";
        };
        environmentFiles = [ /home/albi/secrets/keletikuria.env ];
        ports = [ "10006:8080" ];
      };
      # sus2 = {
      #     image = "sus2";
      #     volumes = [ "/home/albi/www/sus2:/data" ];
      #     environment = {
      #         ConnectionStrings__Database = "Data Source=/data/pings.db";
      #         ASPNETCORE_URLS = "http://100.69.0.2:16744";
      #     };
      #     extraOptions = [ "--network=host" ];
      # };
    };
  };

  services = {
    restic = {
      server = {
        enable = true;
        appendOnly = true;
        extraFlags = [ "--no-auth" ];
        listenAddress = "31415";
      };
      backups = {
        netherite = {
          backupPrepareCommand = ''
            rm -fr /var/lib/backup
            install -d -m 700 -o root -g root /var/lib/backup
            cd /var/lib/backup

            ${pkgs.systemd}/bin/systemctl start backup-vaultwarden.service

            mkdir -p dishelps
            ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/DisHelps/dishelps.db ".backup 'dishelps/dishelps.db'"

            mkdir -p keletikuria
            ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/KeletiKuria/keletikuria.db ".backup 'keletikuria/keletikuria.db'"

            mkdir -p menza
            ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/Menza/menza.db ".backup 'menza/menza.db'"
            cp /home/albi/www/Menza/service-account.json menza/

            mkdir -p sus2
            ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/sus2/pings.db ".backup 'sus2/pings.db'"

            mkdir -p wakapi
            ${pkgs.sqlite}/bin/sqlite3 /var/lib/wakapi/wakapi_db.db ".backup 'wakapi/wakapi_db.db'"
            cp /var/lib/wakapi/config.yml wakapi/
          '';

          paths = [
            "/home/albi/secrets/"
            "/var/lib/backup/"
            "/var/lib/couchdb/.shards/"
            "/var/lib/couchdb/shards/"
            "/var/lib/couchdb/*.couch"
            "/var/lib/couchdb/local.ini"
          ];
          repository = "rest:http://netherite:31415/iron";
          passwordFile = "/home/albi/secrets/restic.key";
          initialize = true;
        };
      };
    };

    nginx = {
      enable = true;
      virtualHosts =
        let
          listen = [
            {
              addr = "100.69.0.2";
              port = 80;
              ssl = false;
            }
          ];
        in
        {
          "waka.alb1.hu" = {
            locations."/".proxyPass = "http://localhost:10010";
            locations."/".proxyWebsockets = true;
            inherit listen;
          };
        };
    };
  };

  services.tailscale.useRoutingFeatures = "both";
}
