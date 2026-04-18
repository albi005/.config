{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/icss.nix
  ];

  networking.hostName = "iron";

  boot.loader.systemd-boot.enable = false;

  # services.statusApi.enable = true;
  # services.statusApi.host = "100.69.0.2";

  services.vaultwarden = {
    enable = false;
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://p.alb1.hu";
      SIGNUPS_ALLOWED = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 10003;
    };
  };

  services.couchdb = {
    # package = stable.couchdb3;
    enable = false;
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

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    oci-containers = {
      backend = "docker";
      containers = {
        alb1 = {
          image = "alb1";
          ports = [ "127.0.0.1:10001:8080" ];
        };
        menza = {
          image = "menza";
          volumes = [ "/home/albi/www/Menza:/data" ];
          environment = {
            ConnectionStrings__Database = "Data Source=/data/menza.db";
            Firebase__ServiceAccount = "/data/service-account.json";
          };
          environmentFiles = [ /home/albi/secrets/menza.env ];
          ports = [ "127.0.0.1:10002:8080" ];
        };
        dishelps = {
          image = "dishelps";
          volumes = [ "/home/albi/www/DisHelps:/data" ];
          environment = {
            ConnectionStrings__Database = "Data Source=/data/dishelps.db";
          };
          ports = [ "127.0.0.1:10005:8080" ];
          extraOptions = [
            "--memory=512m"
            "--memory-swap=1g"
          ];
        };
        keletikuria = {
          image = "keletikuria";
          volumes = [ "/home/albi/www/KeletiKuria:/data" ];
          environment = {
            ConnectionStrings__Database = "Data Source=/data/keletikuria.db";
          };
          environmentFiles = [ /home/albi/secrets/keletikuria.env ];
          ports = [ "127.0.0.1:10006:8080" ];
        };
        redlib = {
          image = "quay.io/redlib/redlib:latest";
          user = "65534:65534";
          # recommended by gemini
          extraOptions = [
            "--read-only"
            "--tmpfs=/tmp"
            "--cap-drop=ALL"
            "--security-opt=no-new-privileges"
            "--memory=512m"
            "--pull=always"
          ];
          environment = {
            REDLIB_ROBOTS_DISABLE_INDEXING = "on";
            REDLIB_DEFAULT_COMMENT_SORT = "top";
            REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION = "on";
            REDLIB_DEFAULT_FIXED_NAVBAR = "off";
            REDLIB_DEFAULT_FRONT_PAGE = "all";
            REDLIB_DEFAULT_POST_SORT = "top";
            REDLIB_DEFAULT_SHOW_NSFW = "on";
            REDLIB_DEFAULT_USE_HLS = "on";
          };
          ports = [ "127.0.0.1:5069:8080" ];
        };
        startsch = {
          image = "startsch";
          ports = [ "127.0.0.1:10007:8080" ];
          environmentFiles = [ /home/albi/secrets/startsch.env ];
          user = "2001:2001";
          environment = {
            ConnectionStrings__Postgres = "Host=/run/postgresql; Username=startsch; Database=startsch";
          };
          volumes = [ "/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432" ];
        };
      };
    };
  };

  # https://github.com/vogler/free-games-claimer
  # sudo docker run --rm -it -p 6080:6080 -v fgc:/fgc/data --pull=always ghcr.io/vogler/free-games-claimer node epic-games
  # noVNC at http://iron:6080
  # services.cron = {
  #     enable = true;
  #     systemCronJobs = [
  #         "0 3 * * * docker run --rm -it -p 6080:6080 -v fgc:/fgc/data --pull=always ghcr.io/vogler/free-games-claimer node epic-games"
  #     ];
  # };

  users.users.startsch = {
    group = "startsch";
    uid = 2001;
    isSystemUser = true;
  };
  users.groups.startsch.gid = 2001;

  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [
        "startsch"
      ];
      ensureUsers = [
        {
          name = "startsch";
          ensureDBOwnership = true;
        }
      ];
      package = pkgs.postgresql_17_jit;
    };
    restic = {
      server = {
        enable = true;
        appendOnly = true;
        extraFlags = [ "--no-auth" ];
        listenAddress = "31415";
      };
      backups = {
        redstone = {
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

            mkdir -p startsch
            ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump startsch > startsch/startsch.sql

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
          repository = "rest:http://redstone:31415/iron";
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
            locations."/".proxyPass = "http://127.0.0.1:10010";
            locations."/".proxyWebsockets = true;
            inherit listen;
          };
          "r.alb1.hu" = {
            locations."/".proxyPass = "http://127.0.0.1:5069";
            locations."/".proxyWebsockets = true;
            inherit listen;
          };
          "home.alb1.hu" = {
            locations."/".proxyPass = "http://127.0.0.1:8123";
            locations."/".proxyWebsockets = true;
            inherit listen;
          };
        };
    };
  };

  services.tailscale.useRoutingFeatures = "server";

  hardware.bluetooth.enable = true;
  # https://github.com/sweenu/nixfiles/blob/eff799274616b1c9679cf6cb73f4640617b5a0b3/profiles/core/base.nix#L92-L119
  services = {
    avahi = {
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        userServices = true;
      };
    };
    # not yet available in nixpkgs stable
    # resolved = {
    #   settings.Resolve = {
    #     MulticastDNS = "no";
    #   };
    # };
    # https://github.com/sweenu/nixfiles/blob/eff799274616b1c9679cf6cb73f4640617b5a0b3/hosts/najdorf/hass.nix#L138-L156
    matter-server = {
      enable = true;
    };
    # defined in module imported from a nixpkgs PR
    openthread-border-router = {
      enable = true;
      package = inputs.otbr.legacyPackages.${pkgs.stdenv.hostPlatform.system}.openthread-border-router;
      backboneInterface = "enp3s0";
      logLevel = "notice";
      rest.listenAddress = "::";
      web = {
        enable = true;
        listenAddress = "::";
      };
      radio = {
        device = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_1CDBD45F096C-if00";
        baudRate = 460800;
        flowControl = false;
      };
    };
  };

  # https://github.com/sweenu/nixfiles/blob/eff799274616b1c9679cf6cb73f4640617b5a0b3/hosts/najdorf/hass.nix#L18-L21
  networking.firewall.extraCommands =
    let
      # https://github.com/sweenu/nixfiles/blob/eff799274616b1c9679cf6cb73f4640617b5a0b3/lib.nix#L4-L6
      openTCPPortForLAN =
        port: "iptables -A nixos-fw -p tcp -s 192.168.1.0/24 --dport ${toString port} -j nixos-fw-accept";
    in
    ''
      # Thread
      ${openTCPPortForLAN 8081}
      ${openTCPPortForLAN 8082}
    '';

  services = {
    home-assistant = {
      enable = true;
      extraComponents = [
        # "apple_tv" # looks for it for some reason
        "androidtv_remote"
        "cast"
        "default_config"
        "epic_games_store" # idk
        "esphome"
        "ffmpeg"
        "google"
        "google_translate" # TTS fallback for wyoming-piper
        "homekit"
        "improv_ble"
        "ipp"
        "isal" # fast compression
        "matter"
        "met"
        # "meteo_france"
        "mobile_app"
        # "music_assistant"
        # "open_router"
        "otbr"
        # "overkiz" # needed for somfy
        "shelly"
        # "somfy"
        # "spotify"
        "switchbot" # idk came up after pairing androidtv
        "thread"
        "upnp"
        # "wyoming"
        "xiaomi_miio"
      ];
      customComponents = with pkgs; [
        # bbox
        # dawarich-ha
        home-assistant-custom-components.xiaomi_miot
        # extended_openai_conversation
        # openai-whisper-cloud
      ];
      config = {
        # automation = "!include automations.yaml";
        # script = "!include scripts.yaml";
        homeassistant = {
          name = "Home";
          # latitude = "!secret latitude";
          # longitude = "!secret longitude";
          # elevation = "!secret elevation";
          unit_system = "metric";
          temperature_unit = "C";
          external_url = "http://home.alb1.hu";
          internal_url = "http://home.alb1.hu";
        };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
            # serverIP
            "::1"
            # serverIPv6
          ];
        };

        # Default config except `backup`, `cloud`, `go2rtc`
        assist_pipeline = { };
        bluetooth = { };
        config = { };
        conversation = { };
        dhcp = { };
        energy = { };
        history = { };
        homeassistant_alerts = { };
        image_upload = { };
        logbook = { };
        media_source = { };
        mobile_app = { };
        my = { };
        ssdp = { };
        stream = { };
        sun = { };
        usage_prediction = { };
        usb = { };
        webhook = { };
        zeroconf = { };
      };
      configWritable = true;
      # openFirewall = true;
    };
  };

  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  #   publish = {
  #     enable = true;
  #     addresses = true;
  #   };
  # };

  # networking.firewall.extraCommands = ''
  #   iptables -A INPUT -p tcp --dport 8080 ! -i lo -j DROP
  #   iptables -A INPUT -p tcp --dport 8081 ! -i lo -j DROP
  # '';

  # # Thread Border Agent UDP port (dynamic in 49152+ range, needed for Matter commissioning)
  # networking.firewall.allowedUDPPortRanges = [
  #   {
  #     from = 49152;
  #     to = 49200;
  #   }
  # ];

  # virtualisation.oci-containers.containers.otbr = {
  #   image = "denniswitt/homeassistant-otbr:latest";
  #   extraOptions = [
  #     "--network=host"
  #     "--cap-add=NET_ADMIN"
  #     "--cap-add=NET_RAW"
  #     "--device=/dev/ttyACM0"
  #     "--device=/dev/net/tun"
  #   ];
  #   environment = {
  #     DEVICE = "/dev/ttyACM0";
  #     BAUDRATE = "460800";
  #     FLOW_CONTROL = "0";
  #     BACKBONE_IF = "enp3s0";
  #     OTBR_LOG_LEVEL = "info";
  #     OTBR_REST_PORT = "8081";
  #     FIREWALL = "0";
  #     NAT64 = "0";
  #   };
  #   volumes = [ "/var/lib/otbr:/data" ];
  # };

  # services.matter-server.enable = true;

  # services.home-assistant = {
  #   enable = true;
  #   extraComponents = [
  #     "analytics"
  #     "google_translate"
  #     "met"
  #     "radio_browser"
  #     "shopping_list"
  #     "isal"
  #     "matter"
  #     "thread"
  #     "otbr"
  #     "switchbot"
  #     "cast"
  #   ];
  #   extraPackages =
  #     ps: with ps; [
  #       universal-silabs-flasher
  #     ];
  #   config = {
  #     default_config = { };
  #     http = {
  #       server_host = "::1";
  #       trusted_proxies = [ "::1" ];
  #       use_x_forwarded_for = true;
  #     };
  #     "automation ui" = "!include automations.yaml";
  #     "scene ui" = "!include scenes.yaml";
  #     "script ui" = "!include scripts.yaml";
  #   };
  # };

  # systemd.tmpfiles.rules = [
  #   "f /var/lib/hass/automations.yaml 0644 hass hass"
  #   "f /var/lib/hass/scenes.yaml 0644 hass hass"
  #   "f /var/lib/hass/scripts.yaml 0644 hass hass"
  # ];
}
