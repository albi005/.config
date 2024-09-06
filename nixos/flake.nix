{
  description = "albi's nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager

            ./hosts/${hostname}/configuration.nix

            {
              _module.args = {
                inputs = inputs;
                stable = inputs.nixpkgs-stable.legacyPackages.${system};
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        netherite = mkHost "netherite";
        iron = mkHost "iron";
        water = mkHost "water";
        slime = mkHost "slime";
      };
    };
}
