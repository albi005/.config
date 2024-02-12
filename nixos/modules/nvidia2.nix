#https://github.com/dmadisetti/.dots/blob/main/nix/machines/lambda.nix#L63
{ config, pkgs, ... }:
{
      # nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package =
    pkgs.linuxKernel.packages.linux_6_1.nvidia_x11;
  hardware.nvidia.modesetting.enable = true;
  # hardware.nvidia.prime.offload.enable = true;
  environment.systemPackages = with pkgs; [ nvidia-docker ];
  # something broke though
  services.xserver.dpi = 110;
  environment.variables = { GDK_SCALE = "0.3"; };

}
