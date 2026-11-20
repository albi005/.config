# included by machines that are always-on servers. don't import on servers also used as desktops.

{
  config,
  ...
}:
{
  system.autoUpgrade = {
    enable = true;
    dates = "03:33";
    flake = "path:${config.users.users.albi.home}/.config/nixos#${config.networking.hostName}";
    flags = [
      "--recreate-lock-file" # update everything
      # "--no-write-lock-file"
      "--print-build-logs"
    ];
    persistent = false; # don't run at startup
    allowReboot = true;
  };

  # allow root to access the git repo of the nix flake.
  # fixes "dubious ownership" error when running autoUpgrade.
  # if you have a better fix send me an email <3
  # btw the error only happens when the working tree is clean
  programs.git.config.safe.directory = "/home/albi/.config/.git";

  nix.gc = {
    automatic = true;
    dates = "04:11";
    options = "--delete-older-than 30d";
    persistent = false;
  };
}
