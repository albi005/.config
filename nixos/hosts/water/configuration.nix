{
  pkgs,
  nixos-unstable,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dotnet.nix
    ../../modules/cloudflared.nix
  ];

  networking = {
    hostName = "water"; # Define your hostname.
    networkmanager.wifi.macAddress = "permanent";
    # networkmanager.enable = lib.mkForce false; # wifi driver no longer supported omegalul
    # wireless.iwd.enable = false; # no deps wifi daemon
  };

  # Tighter disk-space guardrails for water's 128 GB NixOS partition.
  # Regular updates arrive pre-built from CI + Cloudflare R2 via comin;
  # redstone remains configured below as an optional remote builder for local tests.
  albi.gitops = {
    gcRetention = "7d";
    minFreeGiB = 5;
    maxFreeGiB = 12;
    bootEntryLimit = 5;
  };

  # virtualisation.docker.enable = true;

  services.postgresql = {
    # enable = true;
    enableTCPIP = true;
    ensureDatabases = [ "albi" ];
    ensureUsers = [
      {
        name = "albi";
        ensureDBOwnership = true;
      }
    ];
    package = pkgs.postgresql_18_jit;
  };

  # virtualisation.oci-containers = {
  #   backend = "docker";
  #   containers = {
  #     dfv = {
  #       image = "mcr.microsoft.com/mssql/server:2022-latest";
  #       volumes = [
  #         "/var/lib/dfvdb/data:/var/opt/mssql/data"
  #         "/var/lib/dfvdb/log:/var/opt/mssql/log"
  #         "/var/lib/dfvdb/secrets:/var/opt/mssql/secrets"
  #       ];
  #       user = "root";
  #       environment = {
  #         ACCEPT_EULA = "Y";
  #         MSSQL_SA_PASSWORD = "<YourStrong!Passw0rd>";
  #       };
  #       ports = [ "1433:1433" ];
  #     };
  #   };
  # };

  nix = {
    # settings.trusted-users = ["root" "albi"];

    # Remote builders are best-effort: the local machine stays available as a
    # builder, so an unreachable builder just means the build happens locally.
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "redstone";
        sshUser = "albi";
        systems = [ "x86_64-linux" ];
        maxJobs = 8;
        # The legacy `ssh` protocol remote-builds via the privileged
        # BuildDerivation RPC, which a non-trusted `albi` may not use
        # ("you are not privileged to build input-addressed derivations").
        # `ssh-ng` copies the derivation closure instead and needs no trust.
        protocol = "ssh-ng";
      }
      # {
      #   hostName = "netherite";
      #   sshUser = "albi";
      #   systems = [ "x86_64-linux" ];
      #   maxJobs = 8;
      # }
    ];

    settings = {
      # Unreachable substituters are skipped, and `fallback` makes Nix build
      # from source instead of failing when a substitute cannot be fetched.
      substituters = [
        "ssh://albi@redstone?trusted=true"
        # "ssh://albi@netherite?trusted=true"
      ];
      builders-use-substitutes = true;
      fallback = true;
      connect-timeout = 5; # fail over quickly when a builder/substituter is down
    };
  };

  boot.supportedFilesystems = [ "apfs" ];

  environment.systemPackages = with pkgs; [
    # jetbrains.idea-ultimate
    # jetbrains.rider
    # nixos-unstable.jetbrains.rider
    # jetbrains.webstorm
    # prisma
  ];

  # use function keys instead of media keys by default
  # https://wiki.archlinux.org/title/Apple_Keyboard
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  home-manager.users.albi = { ... }: {
    home.file.".config/hypr/host.lua".text = ''
      hl.config{input={kb_options='caps:swapescape'}}
      -- `kb_options = 'grp:win_space_toggle'` is supposed to do this but doesn't work on mac
      hl.bind('SUPER + SPACE', hl.dsp.exec_cmd'hyprctl switchxkblayout apple-inc.-apple-internal-keyboard-/-trackpad next')
    '';
  };
}
