{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "redstone";

  virtualisation.docker.enable = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  users.users.albi.packages = with pkgs; [
    jetbrains.clion
    jetbrains.idea-ultimate
  ];

  services = {
    restic = {
      backups = {
        netherite = {
          backupPrepareCommand = ''
            rm -fr /var/lib/backup
            install -d -m 700 -o root -g root /var/lib/backup
            cd /var/lib/backup

            mkdir -p sus2
            ${pkgs.sqlite}/bin/sqlite3 /home/albi/www/sus2/pings.db ".backup 'sus2/pings.db'"
          '';

          paths = [
            "/home/albi/secrets/"
            "/var/lib/backup/"
          ];
          repository = "rest:http://netherite:31415/redstone";
          passwordFile = "/home/albi/secrets/restic.key";
          initialize = true;
        };
      };
    };
  };

  # virtualisation.oci-containers = {
  #     backend = "docker";
  #     containers = {
  #         sus2 = {
  #             image = "sus2";
  #             volumes = [ "/home/albi/www/sus2:/data" ];
  #             environment = {
  #                 ConnectionStrings__Database = "Data Source=/data/pings.db";
  #                 ASPNETCORE_URLS = "http://*:16744";
  #             };
  #             extraOptions = [ "--network=host" ];
  #         };
  #     };
  # };

  services.tailscale.useRoutingFeatures = "both";

  systemd.services.nzxt = {
    description = "NZXT Kraken and Smart Device V1 setup";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.liquidctl}/bin/liquidctl initialize all"
        "${pkgs.liquidctl}/bin/liquidctl --match Kraken set sync color off"
        "${pkgs.liquidctl}/bin/liquidctl --match Smart set led color off"
      ];
    };
  };

  # systemd.targets.sleep.enable = true;
  # systemd.targets.suspend.enable = false;
  # systemd.targets.hibernate.enable = false;
  # systemd.targets.hybrid-sleep.enable = false;

  fileSystems = {
    # "/mnt/hdd" = {
    #     device = "/dev/disk/by-uuid/560AFE250AFE01B3";
    #     fsType = "ntfs3";
    # };
    # "/mnt/win11" = {
    #     device = "/dev/disk/by-uuid/8014EE8214EE7A94";
    #     fsType = "ntfs-3g";
    # };
  };
}
