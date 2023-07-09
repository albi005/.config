{ config, pkgs, ... }:

{
  networking.hostName = "redstone"; # Define your hostname.

  imports =
    [
      ../../common-configuration.nix
      ./hardware-configuration.nix
    ];

  fileSystems."/mnt/hdd" =
    { device = "/dev/disk/by-uuid/560AFE250AFE01B3";
      fsType = "ntfs3";
    };

  fileSystems."/mnt/popos" =
    { device = "/dev/disk/by-uuid/cd8454ca-b374-43b4-8285-570e3216a6fa";
      fsType = "ext4";
    };
}

