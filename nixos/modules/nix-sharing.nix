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
  nix = {
    # Needed on `redstone` to accept unsigned local inputs over `ssh-ng`, and
    # on `netherite`/`water` to use the `ssh://...?trusted=true` substituter.
    # Adds no real privilege: `albi` is already in `wheel` on all three hosts.
    settings = {
      trusted-users = [ "albi" ];
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
    # redstone's nix-daemon and falls back to local builds after connect-timeout
    # when redstone is offline.
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
