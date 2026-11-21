# Pull-based NixOS GitOps via comin (https://github.com/nlewo/comin).
#
# Workflow:
#   - Machines track `main` (`switch`).
#   - To test changes or a flake.lock update on one host, push a `host/<hostname>`
#     branch — comin activates it with `test` (doesn't touch boot entries).
#   - Merge a PR into `main` (GitHub auto-deletes `host/<hostname>`) and the host
#     automatically returns to `main`.
{
  config,
  lib,
  ...
}:
{
  services.comin = {
    enable = lib.mkDefault true;
    hostname = config.networking.hostName;
    repositorySubdir = "nixos";

    remotes = [
      {
        name = "origin";
        url = "https://github.com/albi005/.config.git";
        # Disable automatic polling on `water` (unreliable connection / laptop);
        # trigger manually with `comin fetch` (`gf`).
        poller.period = if config.networking.hostName == "water" then 0 else 60;
        branches = {
          main = {
            name = "main";
            operation = "switch";
          };
          testing = {
            name = "host/${config.networking.hostName}";
            operation = "test";
          };
        };
      }
    ];

    # Keep Prometheus metrics bound to localhost (default is 0.0.0.0:4243,
    # which would be exposed on hosts with the firewall disabled like `slime`).
    exporter.listen_address = "127.0.0.1";

    # Bound retained profiles/boot entries so automatic updates don't fill disk.
    retention = {
      deployment_boot_entry_capacity = 3;
      deployment_successful_capacity = 3;
      deployment_any_capacity = 5;
    };
  };
}
