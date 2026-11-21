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

    # Bound retained profiles/boot entries so automatic updates don't fill disk.
    retention = {
      deployment_boot_entry_capacity = 3;
      deployment_successful_capacity = 3;
      deployment_any_capacity = 5;
    };
  };
}
