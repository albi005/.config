{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dotnet.nix
  ];

  networking.hostName = "water"; # Define your hostname.
  networking.networkmanager.wifi.macAddress = "permanent";
  # networking.networkmanager.enable = lib.mkForce false;
  networking.wireless.iwd.enable = false; # no deps wifi daemon
  # virtualisation.docker.enable = true;
  # services.postgresql.enable = true;

  # nix.settings.trusted-users = ["root" "albi"];

  nix.buildMachines = [
    {
      hostName = "redstone";
      sshUser = "albi";
      systems = ["x86_64-linux"];
      maxJobs = 8;
    }
  ];

  nix.settings.substituters = ["ssh://albi@redstone"];

  boot.supportedFilesystems = ["apfs"];

  environment.systemPackages = with pkgs; [
    impala # tui for iwd
    uppaal
    bun
    jetbrains.idea-ultimate
    jetbrains.rider
    # jetbrains.webstorm
    # prisma
    # dotnet-sdk_8
  ];

  # use function keys instead of media keys by default
  # https://wiki.archlinux.org/title/Apple_Keyboard
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  home-manager.users.albi = {...}: {
    home.file.".config/hypr/host.conf".text = ''
      input {
          kb_options = caps:swapescape
      }
    '';
  };
}
