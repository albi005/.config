{
  description = "albi's nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
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
                stable = import inputs.nixpkgs-stable {
                  system = system;
                  config.allowUnfree = true;
                  config.permittedInsecurePackages = [
                    "aspnetcore-runtime-6.0.36"
                    "dotnet-sdk-6.0.428"
                  ];
                };
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        iron = mkHost "iron";
        netherite = mkHost "netherite";
        redstone = mkHost "redstone";
        slime = mkHost "slime";
        water = mkHost "water";
      };
    };
}
