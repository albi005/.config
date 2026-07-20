{ pkgs, nixos-unstable, ... }:
{
  environment.systemPackages = [
    nixos-unstable.android-studio
    nixos-unstable.android-tools
    pkgs.scrcpy
    nixos-unstable.jadx
    nixos-unstable.android-cli
  ];
}
