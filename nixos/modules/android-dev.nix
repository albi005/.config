{ pkgs, nixos-unstable, ... }:
{
  environment.systemPackages = [
    nixos-unstable.android-studio
    pkgs.scrcpy
    nixos-unstable.jadx
  ];

  programs.adb.enable = true;
}
