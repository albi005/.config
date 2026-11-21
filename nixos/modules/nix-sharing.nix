# Derivation sharing and best-effort remote builds over Tailscale SSH,
# strictly between trusted personal hosts (redstone, netherite, water).
#
# Do NOT import on servers (`iron`, `slime`):
# - `iron` is public-facing and should have zero outbound SSH or trust from desktops.
# - `slime` is on a separate tailnet that stays isolated.
# `netherite` consumes/offloads to `redstone` but does not serve (32 GB/week dorm limit).
{
  config,
  lib,
  ...
}:
let
  isRedstone = config.networking.hostName == "redstone";
in
{
  # `nix.settings.connect-timeout` only applies to HTTP (libcurl), not OpenSSH.
  # Give system-wide SSH (used by nix-daemon as root) a short timeout so builds
  # fall back locally in 5s instead of hanging ~127s when `redstone` is offline.
  programs.ssh.extraConfig = lib.mkIf (!isRedstone) ''
    Host redstone
      ConnectTimeout 5
      ServerAliveInterval 15
      ServerAliveCountMax 2
      BatchMode yes
  '';

  nix = {
    settings = {
      # Needed on `redstone` so `nix-daemon` accepts unsigned local inputs
      # copied over `ssh-ng`. Adds no real privilege: `albi` is already in `wheel`.
      trusted-users = lib.mkIf isRedstone [ "albi" ];
      # Priority 45 (>40) keeps cache.nixos.org first for upstream nixpkgs
      # while pulling custom derivations from redstone when it's online.
      substituters = lib.mkIf (!isRedstone) [
        "ssh://albi@redstone?trusted=true&priority=45&compress=true"
      ];
      builders-use-substitutes = true;
      fallback = true;
      connect-timeout = 5;
    };

    # Best-effort offloading to redstone: shares in-progress builds natively via
    # redstone's nix-daemon and falls back to local builds when redstone is offline.
    distributedBuilds = lib.mkIf (!isRedstone) true;
    buildMachines = lib.mkIf (!isRedstone) [
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
}
