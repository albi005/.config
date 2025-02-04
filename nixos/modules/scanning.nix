{ pkgs, ... }:
{
  hardware.sane.enable = true; # scanner daemon
  environment.systemPackages = with pkgs; [
    naps2 # scanner gui
  ];
  users.users.albi.extraGroups = [
    "scanner"
    "lp"
  ];
}
