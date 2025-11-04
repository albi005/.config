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

  networking = {
    hostName = "water"; # Define your hostname.
    networkmanager.wifi.macAddress = "permanent";
    # networkmanager.enable = lib.mkForce false;
    wireless.iwd.enable = false; # no deps wifi daemon
  };

  # virtualisation.docker.enable = true;
  # services.postgresql.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      dfv = {
        image = "mcr.microsoft.com/mssql/server:2022-latest";
        volumes = [
          "/var/lib/dfvdb/data:/var/opt/mssql/data"
          "/var/lib/dfvdb/log:/var/opt/mssql/log"
          "/var/lib/dfvdb/secrets:/var/opt/mssql/secrets"
        ];
        user = "root";
        environment = {
          ACCEPT_EULA = "Y";
          MSSQL_SA_PASSWORD = "<YourStrong!Passw0rd>";
        };
        ports = [ "1433:1433" ];
      };
    };
  };

  nix = {
    # settings.trusted-users = ["root" "albi"];

    buildMachines = [
      {
        hostName = "redstone";
        sshUser = "albi";
        systems = ["x86_64-linux"];
        maxJobs = 8;
      }
    ];

    settings = {
      substituters = ["ssh://albi@redstone?trusted=true"];
      builders-use-substitutes = true;
    };
  };

  boot.supportedFilesystems = ["apfs"];

  environment.systemPackages = with pkgs; [
    # jetbrains.idea-ultimate
    jetbrains.rider
    jetbrains.webstorm
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
