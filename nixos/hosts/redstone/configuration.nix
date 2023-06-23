{ config, pkgs, ... }:

{
  networking.hostName = "nixos"; # Define your hostname.

  imports =
    [
      ../../common-configuration.nix
      ./hardware-configuration.nix
    ];

}

