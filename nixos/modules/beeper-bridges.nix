{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.beeperBridges;

  bbctl = pkgs.callPackage ../pkgs/bbctl.nix { };

  mkService =
    name: bridge:
    let
      args = [
        "run"
        name
      ]
      ++ lib.optionals (bridge.type != null) [
        "--type"
        bridge.type
      ]
      ++ bridge.extraArgs;
    in
    {
      description = "Beeper self-hosted bridge '${name}'";
      documentation = [ "https://github.com/beeper/bridge-manager" ];

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOME = cfg.home;
        # Some bridges use ffmpeg for media conversion.
        PATH = lib.makeBinPath [
          pkgs.ffmpeg
          pkgs.python3
          pkgs.git
        ];
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.home;

        ExecStart = lib.escapeShellArgs ([ "${cfg.package}/bin/bbctl" ] ++ args);

        Restart = "on-failure";
        RestartSec = 10;
        TimeoutStopSec = 30;

        # bbctl keeps its login token, bridge configs and bridge databases in
        # the user's home directory.
        UMask = "0077";
      };
    };
in
{
  options.services.beeperBridges = {
    enable = lib.mkEnableOption "self-hosted Beeper bridges via bbctl";

    package = lib.mkOption {
      type = lib.types.package;
      default = bbctl;
      defaultText = lib.literalExpression "pkgs.callPackage ../pkgs/bbctl.nix { }";
      description = "The bbctl package to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "albi";
      description = "User that owns the bbctl login and runs the bridges.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group that runs the bridges.";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.${cfg.user}.home;
      defaultText = lib.literalExpression "config.users.users.${cfg.user}.home";
      description = ''
        HOME for the bridge services. bbctl stores `config.json` in
        `$HOME/.config/bbctl` and bridge data in `$HOME/.local/share/bbctl`.
        Run `bbctl login` as this user before starting the services.
      '';
    };

    bridges = lib.mkOption {
      default = { };
      description = ''
        Bridges to run, keyed by bridge name. The name must start with `sh-`
        and may only contain a-z, 0-9 and `-`. If the name contains a bridge
        type identifier (e.g. `sh-telegram`) the type can be omitted.
      '';
      example = {
        messenger = {
          name = "sh-messenger";
          type = "meta";
        };
        slack = {
          name = "sh-slack";
          type = "slack";
        };
        discord = {
          name = "sh-discord";
          type = "discord";
        };
        telegram = {
          name = "sh-telegram";
          type = "telegram";
        };
      };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              example = "sh-messenger";
              description = "Bridge name registered with Beeper (must start with `sh-`).";
            };

            type = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "meta";
              description = ''
                bbctl bridge type. See the table in the bridge-manager README.
                Messenger is `meta`; Slack is `slack`; Discord is `discord`;
                Telegram is `telegram`.
              '';
            };

            extraArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "--no-update" ];
              description = "Extra arguments passed to `bbctl run`.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    assertions = [
      {
        assertion = config.users.users ? ${cfg.user};
        message = "services.beeperBridges.user '${cfg.user}' does not exist.";
      }
    ];

    systemd.services = lib.mapAttrs' (
      key: bridge: lib.nameValuePair "beeper-bridge-${key}" (mkService bridge.name bridge)
    ) cfg.bridges;
  };
}
