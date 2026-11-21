# Pull-based NixOS GitOps (comin) + shared Cloudflare R2 binary cache +
# disk-usage guardrails across servers and desktops.
#
# How it works:
#   1. PRs to albi005/.config are built on GitHub Actions; non-upstream store
#      paths are signed and uploaded to Cloudflare R2 (10 GB free, zero egress).
#   2. Merging to `main` triggers CI to fast-forward `deploy/<hostname>` ONLY
#      after that host's closure is built and cached in R2.
#   3. Every NixOS host runs `comin`, pulling `deploy/<hostname>` over outbound
#      HTTPS (no inbound ports, no SSH keys in CI, slime's tailnet stays isolated).
#      Because CI already pushed the closure, weak hosts (iron, water) never
#      compile locally and bandwidth-capped hosts (netherite) only fetch deltas.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.albi.gitops;
  isDesktop = cfg.role == "desktop";
  isServer = cfg.role == "server";
  hasCustomCache = cfg.cache.url != null && cfg.cache.publicKey != null;
in
{
  options.albi.gitops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable pull-based GitOps deployment via comin.";
    };

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "desktop"
      ];
      default = "desktop";
      description = ''
        Host deployment profile:
        - "server": immediate unattended switch, Prometheus exporter on localhost:4243, 60s poll.
        - "desktop": desktop notifications + 120s auto-confirm window (pause with `comin suspend`), 300s poll.
      '';
    };

    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/albi005/.config.git";
      description = "Git repository URL polled by comin.";
    };

    deployBranch = lib.mkOption {
      type = lib.types.str;
      default = "deploy/${config.networking.hostName}";
      defaultText = lib.literalExpression ''"deploy/''${config.networking.hostName}"'';
      description = "CI-gated branch that comin tracks and activates.";
    };

    testingBranch = lib.mkOption {
      type = lib.types.str;
      default = "testing/${config.networking.hostName}";
      defaultText = lib.literalExpression ''"testing/''${config.networking.hostName}"'';
      description = "Optional branch for ephemeral `switch-to-configuration test` activations.";
    };

    pollPeriod = lib.mkOption {
      type = lib.types.int;
      default = if isServer then 60 else 300;
      description = "Git polling interval in seconds.";
    };

    cache = {
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        # Set this once your Cloudflare R2 bucket + custom domain is live (see nixos/GITOPS.md),
        # e.g. "https://cache.alb1.hu". Leaving null safely disables the custom substituter until configured.
        default = null;
        example = "https://cache.alb1.hu";
        description = "Public HTTPS URL of the shared Nix binary cache (Cloudflare R2).";
      };

      publicKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "cache.alb1.hu-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        description = "Nix signing public key corresponding to the R2 binary cache.";
      };
    };

    gcRetention = lib.mkOption {
      type = lib.types.str;
      default = if isServer then "14d" else "21d";
      description = "Age threshold for automatic `nix-collect-garbage --delete-older-than`.";
    };

    minFreeGiB = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Trigger automatic Nix GC during builds/downloads when free disk drops below this (GiB).";
    };

    maxFreeGiB = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "Target free disk space (GiB) when min-free automatic GC triggers.";
    };

    bootEntryLimit = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Maximum systemd-boot generations retained in /boot.";
    };
  };

  config = {
    # Shared Cloudflare R2 binary cache + resilient fallback + disk guardrails
    nix = {
      settings = {
        auto-optimise-store = true;
        fallback = lib.mkDefault true;
        connect-timeout = lib.mkDefault 5;
        min-free = lib.mkDefault (cfg.minFreeGiB * 1024 * 1024 * 1024);
        max-free = lib.mkDefault (cfg.maxFreeGiB * 1024 * 1024 * 1024);
      }
      // lib.optionalAttrs hasCustomCache {
        substituters = [ cfg.cache.url ];
        trusted-public-keys = [ cfg.cache.publicKey ];
      };

      optimise = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault [ "weekly" ];
      };

      gc = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "04:11";
        options = lib.mkDefault "--delete-older-than ${cfg.gcRetention}";
        persistent = lib.mkDefault (!isServer);
      };
    };

    # Prevent /boot from filling up across automatic GitOps deployments
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault cfg.bootEntryLimit;

    # Keep Docker image layers from piling up when OCI containers update
    virtualisation.docker.autoPrune = lib.mkIf config.virtualisation.docker.enable {
      enable = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      flags = lib.mkDefault [
        "--all"
        "--filter"
        "until=168h"
      ];
    };

    # Pull-based GitOps reconciler (ArgoCD for NixOS)
    services.comin = lib.mkIf cfg.enable {
      enable = true;
      hostname = config.networking.hostName;
      repositoryType = "flake";
      repositorySubdir = "nixos";

      remotes = [
        {
          name = "origin";
          url = cfg.repoUrl;
          poller.period = cfg.pollPeriod;
          branches = {
            main = {
              name = cfg.deployBranch;
              operation = "switch";
            };
            testing = {
              name = cfg.testingBranch;
              operation = "test";
            };
          };
        }
      ];

      # Servers deploy immediately; desktops show a DBus notification and give
      # a 2-minute window (cancel/pause via `comin suspend`) before switching.
      deployConfirmer =
        if isDesktop then
          {
            mode = "auto";
            autoconfirm_duration = 120;
          }
        else
          {
            mode = "without";
          };

      desktop = {
        enable = isDesktop;
        title = "NixOS GitOps (${config.networking.hostName})";
      };

      exporter = {
        listen_address = "127.0.0.1";
        port = 4243;
      };

      # Keep disk usage bounded by limiting comin-managed generations/profiles
      retention = {
        deployment_boot_entry_capacity = 3;
        deployment_successful_capacity = 3;
        deployment_any_capacity = 5;
      };
    };
  };
}
