{
  description = "albi's nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # helix-editor language-server that sends wakatime (coding time tracker) heartbeats
    wakatime-ls = {
      url = "github:mrnossiom/wakatime-ls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    mkHost = hostname:
      nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          {
            _module.args = {
              inputs = inputs;
              nvf = inputs.nvf;
              stable = import inputs.nixpkgs-stable {
                system = system;
                config.allowUnfree = true;
                config.permittedInsecurePackages = [
                  "aspnetcore-runtime-6.0.36"
                  "dotnet-sdk-6.0.428"
                ];
              };
              nixos-25_05 = import inputs.nixpkgs-25_05 {
                system = system;
                config.allowUnfree = true;
              };
            };
          }

          home-manager.nixosModules.home-manager
          inputs.nvf.nixosModules.default

          ./hosts/${hostname}/configuration.nix
        ];
      };
  in {
    nixosConfigurations = {
      iron = mkHost "iron";
      netherite = mkHost "netherite";
      redstone = mkHost "redstone";
      slime = mkHost "slime";
      water = mkHost "water";
    };
  };
}
