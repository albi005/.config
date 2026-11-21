# Example: Deploying a native Nix app with Postgres + SQLite/state + Nginx + Backups
#
# Use `albi.apps.<name>` with `runtime = "systemd"` for zero Docker overhead.
# If a Nix-built app ever needs container isolation, you can instead pass:
#   runtime = "oci";
#   image = "my-nix-app:latest";
#   imageFile = pkgs.dockerTools.buildLayeredImage {
#     name = "my-nix-app";
#     tag = "latest";
#     config.Cmd = [ (lib.getExe myPkg) ];
#   };
{
  pkgs,
  ...
}:
let
  myPkg = pkgs.callPackage ../../alb1/package.nix { };
in
{
  albi.apps.my-nix-app = {
    description = "Example native Nix app";
    runtime = "systemd";
    package = myPkg;
    port = 10021;
    memoryMax = "512M";

    stateDir = "/var/lib/my-nix-app";
    postgres.enable = true;

    environment = {
      ASPNETCORE_URLS = "http://127.0.0.1:10021";
      ConnectionStrings__Postgres = "Host=/run/postgresql; Username=my-nix-app; Database=my-nix-app";
    };
    environmentFiles = [ /home/albi/secrets/my-nix-app.env ];

    expose = {
      enable = true;
      domain = "mynixapp.alb1.hu";
      listenAddr = "100.69.0.2";
    };

    backup = {
      postgres = true;
      sqlitePaths = [ "/var/lib/my-nix-app/app.db" ];
    };
  };
}
