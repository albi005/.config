{ config, pkgs, ... }:

let
  unstable = import
    (builtins.fetchTarball "https://github.com/nixos/nixpkgs/tarball/nixos-unstable")
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in
{
  imports =
    [
         <home-manager/nix-darwin>
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Use a custom configuration.nix location.
# $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixos/hosts/air/configuration.nix
    environment.darwinConfig = "$HOME/.config/nixos/hosts/air/configuration.nix";

    users.users.dishelps = {
        name = "dishelps";
        home = "/Users/dishelps";
    };

    environment.systemPackages = with pkgs;
    [
        neovim
        tmux
        unstable.nixd
        alacritty
        lsd
        nil
        neofetch
    ];

# Auto upgrade nix package and the daemon service.
    services.nix-daemon.enable = true;
# nix.package = pkgs.nix;

# Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh.enable = true;  # default shell on catalina
    programs.bash.enable = true;
    environment.shells = with pkgs; [ bashInteractive zsh ];

    fonts.fontDir.enable = true;
    fonts.fonts = with pkgs; [
        (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
    ];

    home-manager.users.dishelps = import ../../home.nix;

# Used for backwards compatibility, please read the changelog before changing.
# $ darwin-rebuild changelog
    system.stateVersion = 4;
}
