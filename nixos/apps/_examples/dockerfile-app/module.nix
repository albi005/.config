# Example: Deploying a Dockerfile-based app with ZERO container registry!
#
# 1. Copy this directory to `nixos/apps/<myapp>/`.
# 2. Add a 15-line `.github/workflows/deploy.yml` to your app repo calling
#    `albi005/.config/.github/workflows/reusable-deploy-dockerfile-app.yml@main`.
# 3. Import this snippet in your target host's configuration.nix (e.g. hosts/iron/configuration.nix).
#
# On every push to main in your app repo:
#   GHA builds Dockerfile -> exports .tar.gz to GitHub Release (or R2) ->
#   opens PR updating pin.json -> you merge -> CI caches image in R2 ->
#   comin loads imageFile from /nix/store and restarts the container!
{
  lib,
  pkgs,
  ...
}:
let
  pins = import ../../../lib/pins.nix { inherit lib pkgs; };
  pin = pins.readAppPin ./pin.json;
in
{
  albi.apps.my-dockerfile-app = {
    description = "Example Dockerfile app (zero container registry)";
    runtime = "oci";
    inherit (pin) image imageFile;

    port = 10020;
    containerPort = 8080;
    memoryMax = "512m";
    memorySwapMax = "1g";

    # Optional: dedicated UID/GID for PostgreSQL peer auth or host bind mounts
    uid = 2020;
    gid = 2020;

    # Optional: automatic PostgreSQL DB + user + unix socket mount + pg_dump backup hook
    postgres.enable = true;

    environment = {
      ASPNETCORE_ENVIRONMENT = "Production";
      ConnectionStrings__Postgres = "Host=/run/postgresql; Username=my-dockerfile-app; Database=my-dockerfile-app";
    };
    environmentFiles = [ /home/albi/secrets/my-dockerfile-app.env ];

    # Optional: automatic Nginx virtual host on Tailscale IP
    expose = {
      enable = true;
      domain = "myapp.alb1.hu";
      listenAddr = "100.69.0.2";
    };
  };
}
