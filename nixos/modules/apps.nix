# Declarative NixOS application module (inspired by kir-dev/k8s KirDevApp).
#
# Supports three pinned runtimes under one uniform interface:
#   1. "systemd"      - Native Nix derivation running as a hardened systemd service (preferred).
#   2. "oci"          - Nixified OCI container loaded from a Nix store imageFile
#                       (either a Dockerfile tarball from pin.json or dockerTools.buildLayeredImage).
#                       No container registry required!
#   3. "oci-registry" - Third-party OCI image from a registry, strictly digest-pinned (@sha256:...).
#
# Also wires PostgreSQL databases/users, Nginx virtual hosts, systemd resource
# limits, bind mounts, secrets (EnvironmentFile), and Restic backup hooks.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.albi.apps;
  enabledApps = lib.filterAttrs (_: app: app.enable) cfg;

  systemdApps = lib.filterAttrs (_: app: app.runtime == "systemd") enabledApps;
  ociApps = lib.filterAttrs (
    _: app: app.runtime == "oci" || app.runtime == "oci-registry"
  ) enabledApps;
  postgresApps = lib.filterAttrs (_: app: app.postgres.enable) enabledApps;
  exposedApps = lib.filterAttrs (_: app: app.expose.enable) enabledApps;

  # Helper: parse "src:dst" or "path" into host path check
  usesHomePath = paths: lib.any (p: lib.hasPrefix "/home/" p) paths;

  mkSystemdService =
    name: app:
    let
      exe =
        if app.executable != null then "${app.package}/bin/${app.executable}" else lib.getExe app.package;
      cmd = lib.escapeShellArgs ([ exe ] ++ app.args);
      allPaths =
        app.readOnlyPaths
        ++ app.readWritePaths
        ++ lib.optional (app.stateDir != null) app.stateDir
        ++ map toString app.environmentFiles;
      needsHome = usesHomePath allPaths;
      pgDeps = lib.optional app.postgres.enable "postgresql.service";
    in
    {
      description = app.description;
      after = [ "network-online.target" ] ++ pgDeps ++ app.after;
      wants = [ "network-online.target" ] ++ pgDeps ++ app.wants;
      before = app.before;
      wantedBy = [ "multi-user.target" ];

      environment = app.environment;

      serviceConfig = {
        Type = "simple";
        ExecStart = cmd;
        User = app.user;
        Group = app.group;
        Restart = "on-failure";
        RestartSec = "5s";

        # Hardening defaults (can be overridden via extraServiceConfig)
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = if needsHome then "read-only" else true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
      }
      // lib.optionalAttrs (app.stateDir != null) {
        StateDirectory = lib.removePrefix "/var/lib/" app.stateDir;
        WorkingDirectory = app.stateDir;
      }
      // lib.optionalAttrs (app.readOnlyPaths != [ ]) {
        BindReadOnlyPaths = app.readOnlyPaths;
      }
      // lib.optionalAttrs (app.readWritePaths != [ ]) {
        BindPaths = app.readWritePaths;
      }
      // lib.optionalAttrs (app.environmentFiles != [ ]) {
        EnvironmentFile = app.environmentFiles;
      }
      // lib.optionalAttrs (app.memoryMax != null) {
        MemoryMax = app.memoryMax;
      }
      // lib.optionalAttrs (app.memorySwapMax != null) {
        MemorySwapMax = app.memorySwapMax;
      }
      // app.extraServiceConfig;
    };

  mkOciContainer =
    _name: app:
    let
      roVolumes = map (p: "${p}:ro") app.readOnlyPaths;
      rwVolumes =
        app.readWritePaths
        ++ lib.optional (app.stateDir != null) "${app.stateDir}:${app.containerDataDir}"
        ++ lib.optional app.postgres.enable "/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432";
      portBindings =
        lib.optional (app.port != null) "127.0.0.1:${toString app.port}:${toString app.containerPort}"
        ++ app.extraPorts;
      memoryFlags =
        lib.optional (app.memoryMax != null) "--memory=${app.memoryMax}"
        ++ lib.optional (app.memorySwapMax != null) "--memory-swap=${app.memorySwapMax}";
      containerUser =
        if app.uid != null && app.gid != null then "${toString app.uid}:${toString app.gid}" else null;
    in
    {
      inherit (app) image environment environmentFiles;
      ports = portBindings;
      volumes = roVolumes ++ rwVolumes;
      extraOptions = [ "--log-driver=journald" ] ++ memoryFlags ++ app.extraContainerOptions;
    }
    // lib.optionalAttrs (app.imageFile != null) {
      inherit (app) imageFile;
    }
    // lib.optionalAttrs (containerUser != null) {
      user = containerUser;
    };

  mkBackupSnippet =
    name: app:
    let
      sqliteLines = lib.imap0 (
        idx: dbPath:
        let
          base = baseNameOf dbPath;
          outName = if idx == 0 then base else "${toString idx}-${base}";
        in
        ''
          mkdir -p "${name}"
          if [ -f "${dbPath}" ]; then
            ${pkgs.sqlite}/bin/sqlite3 "${dbPath}" ".backup '${name}/${outName}'"
          fi
        ''
      ) app.backup.sqlitePaths;

      extraLines = map (p: ''
        mkdir -p "${name}"
        if [ -e "${p}" ]; then
          cp -r "${p}" "${name}/"
        fi
      '') app.backup.extraPaths;

      pgLines = lib.optional (app.backup.postgres && app.postgres.enable) ''
        mkdir -p "${name}"
        ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dump "${app.postgres.database}" > "${name}/${app.postgres.database}.sql"
      '';
    in
    lib.concatStringsSep "\n" (sqliteLines ++ extraLines ++ pgLines);

  appSubmodule =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable this application.";
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = "${name} application";
          description = "Human-readable systemd unit description.";
        };

        runtime = lib.mkOption {
          type = lib.types.enum [
            "systemd"
            "oci"
            "oci-registry"
          ];
          default = "systemd";
          description = ''
            Execution model:
            - "systemd": Native Nix derivation running as a hardened systemd service.
            - "oci": OCI container loaded from a Nix store imageFile (Dockerfile tarball or buildLayeredImage), no registry required.
            - "oci-registry": Third-party OCI image from a registry, strictly digest-pinned (@sha256:...).
          '';
        };

        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          description = "Nix package derivation (required when runtime = \"systemd\").";
        };

        executable = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Binary name inside package/bin (defaults to lib.getExe package).";
        };

        args = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra CLI arguments passed to the systemd executable.";
        };

        image = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Container image reference (for runtime = \"oci\" or \"oci-registry\").";
        };

        imageFile = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          description = "Nix derivation producing a docker-archive tarball (required when runtime = \"oci\").";
        };

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "Loopback HTTP port on 127.0.0.1 exposed by this app.";
        };

        containerPort = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Internal port inside the container (used with port for OCI runtimes).";
        };

        extraPorts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional docker port mappings (e.g. \"1433:1433\").";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Non-secret environment variables.";
        };

        environmentFiles = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Paths to secret env files loaded at runtime (never stored in Git/Nix store).";
        };

        stateDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Persistent host state directory (StateDirectory for systemd, bind-mounted to containerDataDir for OCI).";
        };

        containerDataDir = lib.mkOption {
          type = lib.types.str;
          default = "/data";
          description = "Mount target inside container when stateDir is set.";
        };

        readOnlyPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Read-only bind mounts in \"hostPath:targetPath\" format.";
        };

        readWritePaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Read-write bind mounts in \"hostPath:targetPath\" format.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "System user to run the app as.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "System group to run the app as.";
        };

        uid = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          description = "Optional fixed UID (recommended for OCI apps that share PostgreSQL peer auth or host volumes).";
        };

        gid = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          description = "Optional fixed GID.";
        };

        createUser = lib.mkOption {
          type = lib.types.bool;
          default = config.runtime == "systemd" || config.uid != null;
          description = "Whether to declaratively create the system user and group.";
        };

        memoryMax = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Memory limit (e.g. \"512m\" / \"512M\" or \"1g\" / \"1G\").";
        };

        memorySwapMax = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Swap limit (e.g. \"1g\" / \"1G\").";
        };

        extraContainerOptions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional flags passed to docker/podman run.";
        };

        extraServiceConfig = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Extra systemd serviceConfig overrides (runtime = \"systemd\").";
        };

        after = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional systemd After= units.";
        };

        before = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional systemd Before= units.";
        };

        wants = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional systemd Wants= units.";
        };

        postgres = {
          enable = lib.mkEnableOption "PostgreSQL database and user for this app";
          database = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "PostgreSQL database name.";
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "PostgreSQL role name (granted ownership of database).";
          };
        };

        expose = {
          enable = lib.mkEnableOption "Nginx reverse proxy virtual host for this app";
          domain = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Virtual host domain name (e.g. \"app.alb1.hu\").";
          };
          listenAddr = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address Nginx listens on for this virtual host (e.g. Tailscale IP).";
          };
          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 80;
            description = "Port Nginx listens on.";
          };
          websockets = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable WebSocket proxying.";
          };
        };

        backup = {
          sqlitePaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "SQLite database files to back up online via sqlite3 .backup.";
          };
          extraPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional files/directories to copy into the restic staging directory.";
          };
          postgres = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Dump this app's PostgreSQL database during backup (when postgres.enable = true).";
          };
        };
      };
    };
in
{
  options.albi = {
    apps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule appSubmodule);
      default = { };
      description = "Declarative pinned applications managed on this NixOS host.";
    };

    appsBackupScript = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      default = lib.concatStringsSep "\n" (lib.mapAttrsToList mkBackupSnippet enabledApps);
      description = ''
        Generated shell snippet backing up all enabled albi.apps databases and extraPaths
        into the current working directory. Interpolate inside restic backupPrepareCommand.
      '';
    };
  };

  config = lib.mkIf (enabledApps != { }) {
    assertions = lib.flatten (
      lib.mapAttrsToList (name: app: [
        {
          assertion = app.runtime != "systemd" || app.package != null;
          message = "albi.apps.${name}: runtime = \"systemd\" requires 'package' to be set.";
        }
        {
          assertion = app.runtime != "oci" || (app.image != null && app.imageFile != null);
          message = "albi.apps.${name}: runtime = \"oci\" requires both 'image' and 'imageFile' (no unpinned local docker images!).";
        }
        {
          assertion =
            app.runtime != "oci-registry" || (app.image != null && lib.hasInfix "@sha256:" app.image);
          message = "albi.apps.${name}: runtime = \"oci-registry\" requires a digest-pinned image ('...@sha256:...'). Use pins.imageRef from nixos/pins/images.json.";
        }
        {
          assertion = !app.expose.enable || (app.expose.domain != "" && app.port != null);
          message = "albi.apps.${name}: expose.enable requires both 'expose.domain' and 'port' to be set.";
        }
      ]) enabledApps
    );

    # System users & groups
    users.users = lib.mapAttrs' (
      _name: app:
      lib.nameValuePair app.user (
        {
          group = app.group;
          isSystemUser = true;
        }
        // lib.optionalAttrs (app.uid != null) { inherit (app) uid; }
      )
    ) (lib.filterAttrs (_: app: app.createUser) enabledApps);

    users.groups = lib.mapAttrs' (
      _name: app: lib.nameValuePair app.group (lib.optionalAttrs (app.gid != null) { inherit (app) gid; })
    ) (lib.filterAttrs (_: app: app.createUser) enabledApps);

    # Native systemd services
    systemd.services =
      (lib.mapAttrs mkSystemdService systemdApps)
      // (lib.mapAttrs'
        (
          name: app:
          let
            backend = config.virtualisation.oci-containers.backend;
            pgDeps = lib.optional app.postgres.enable "postgresql.service";
          in
          lib.nameValuePair "${backend}-${name}" {
            after = pgDeps ++ app.after;
            before = app.before;
            wants = pgDeps ++ app.wants;
          }
        )
        (
          lib.filterAttrs (
            _: app: app.after != [ ] || app.before != [ ] || app.wants != [ ] || app.postgres.enable
          ) ociApps
        )
      );

    # OCI containers
    virtualisation.docker.enable = lib.mkIf (ociApps != { }) (lib.mkDefault true);
    virtualisation.oci-containers = lib.mkIf (ociApps != { }) {
      backend = lib.mkDefault "docker";
      containers = lib.mapAttrs mkOciContainer ociApps;
    };

    # PostgreSQL wiring
    services.postgresql = lib.mkIf (postgresApps != { }) {
      enable = true;
      ensureDatabases = lib.mapAttrsToList (_: app: app.postgres.database) postgresApps;
      ensureUsers = lib.mapAttrsToList (_: app: {
        name = app.postgres.user;
        ensureDBOwnership = true;
      }) postgresApps;
    };

    # Nginx reverse proxy wiring
    services.nginx = lib.mkIf (exposedApps != { }) {
      enable = true;
      virtualHosts = lib.mapAttrs' (
        _name: app:
        lib.nameValuePair app.expose.domain {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString app.port}";
            proxyWebsockets = app.expose.websockets;
          };
          listen = [
            {
              addr = app.expose.listenAddr;
              port = app.expose.listenPort;
              ssl = false;
            }
          ];
        }
      ) exposedApps;
    };
  };
}
