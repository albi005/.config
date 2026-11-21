# Peer-to-peer derivation sharing (harmonia) and best-effort remote builds
# across the main tailnet (redstone, iron, netherite, water).
#
# Do NOT import on `slime` — its tailnet stays isolated.
# `netherite` consumes from peers but does not serve (32 GB/week dorm limit).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixSharing;
  host = config.networking.hostName;

  # Hosts that serve their /nix/store over Tailscale via harmonia (port 5000).
  # Priority > 40 means cache.nixos.org (priority 40) still serves upstream
  # nixpkgs while peers share everything built locally (apps, system closures).
  peers = lib.filter (p: p.name != host) [
    {
      name = "redstone";
      url = "http://redstone:5000?priority=45";
    }
    {
      name = "iron";
      url = "http://iron:5000?priority=46";
    }
  ];

  # Populate after the first switch on redstone & iron (`cat /var/lib/harmonia/cache-pub-key.pem`).
  peerPublicKeys = [
    # "redstone-1:..."
    # "iron-1:..."
  ];

  keyDir = "/var/lib/harmonia";
  privKey = "${keyDir}/cache-priv-key.pem";
  pubKey = "${keyDir}/cache-pub-key.pem";
in
{
  options.nixSharing = {
    serve = lib.mkEnableOption "serve this host's /nix/store over Tailscale via harmonia";

    priority = lib.mkOption {
      type = lib.types.int;
      default = 45;
      description = "Binary cache priority advertised by harmonia (>40 prefers cache.nixos.org for upstream packages).";
    };

    offloadToRedstone = lib.mkEnableOption "offload Nix builds to redstone over ssh-ng (best-effort)";
  };

  config = lib.mkMerge [
    {
      nix.settings = {
        substituters = lib.mkIf (peerPublicKeys != [ ]) (map (p: p.url) peers);
        trusted-public-keys = peerPublicKeys;
        builders-use-substitutes = true;
        fallback = true;
        connect-timeout = 5;
      };
    }

    (lib.mkIf cfg.serve {
      # Socket-activated Rust Nix binary cache. Port 5000 is reachable only over
      # Tailscale because `tailscale0` is a trusted interface and the firewall
      # blocks port 5000 everywhere else.
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ privKey ];
        settings = {
          bind = "[::]:5000";
          priority = cfg.priority;
        };
      };

      # Generate a signing keypair on first boot so harmonia starts cleanly.
      systemd.services.harmonia-keygen = {
        description = "Generate Harmonia binary cache signing key";
        before = [ "harmonia.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = "!${privKey}";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0077";
        };
        script = ''
          install -d -m 700 "${keyDir}"
          ${config.nix.package}/bin/nix-store --generate-binary-cache-key "${host}-1" "${privKey}" "${pubKey}"
          chmod 644 "${pubKey}"
          echo "Generated Harmonia public key (add to nixos/modules/nix-sharing.nix):"
          cat "${pubKey}"
        '';
      };
    })

    (lib.mkIf cfg.offloadToRedstone {
      # Remote builds are best-effort: if redstone is offline, Nix falls back
      # to building locally after connect-timeout.
      nix = {
        distributedBuilds = true;
        buildMachines = [
          {
            hostName = "redstone";
            sshUser = "albi";
            systems = [ "x86_64-linux" ];
            maxJobs = 8;
            # `ssh-ng` copies the derivation closure instead of using the
            # legacy privileged BuildDerivation RPC.
            protocol = "ssh-ng";
          }
        ];
      };
    })
  ];
}
