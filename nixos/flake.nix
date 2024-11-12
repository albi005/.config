{
  description = "albi's nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:ch4og/zen-browser-flake";
    sqldeveloper = {
      url = "https://db.bme.hu/r/sqldeveloper/sqldeveloper-20.4.1.407.0006-no-jre.zip";
      flake = false;
    };
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
                    "oraclejdk-8u281"
                  ];
                  overlays = [
                    (final: prev: {
                      sqldeveloper = prev.sqldeveloper.overrideAttrs (old: {
                        version = "20.4.1.407.0006";
                        src = inputs.sqldeveloper;
                      });
                    })
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
