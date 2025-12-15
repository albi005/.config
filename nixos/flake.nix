{
  description = "albi's nix config";

  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-2505.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-2511.url = "github:NixOS/nixpkgs/nixos-25.11";

    # checks for unsaved or uncommitted changes
    git-leave.url = "github:mrnossiom/git-leave";
    git-leave.inputs.nixpkgs.follows = "nixos-unstable";

    # Using Nix, configure stuff that goes into your /home.
    # Option search: https://home-manager-options.extranix.com/
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixos-2511";

    # nix-based neovim distro
    nvf.url = "github:NotAShelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixos-unstable";

    # helix-editor language-server that sends wakatime (coding time tracker) heartbeats
    wakatime-ls.url = "github:mrnossiom/wakatime-ls";
    wakatime-ls.inputs.nixpkgs.follows = "nixos-unstable";

    # firefox fork
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs =
    inputs:
    let
      mkHost =
        hostname:
        inputs.nixos-2511.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            # set up dependency injection for module parameters.
            # use "inputs", "nvf", "stable", etc. in a module's parameter object
            {
              _module.args = {
                inputs = inputs;
                nixos-unstable = import inputs.nixos-unstable {
                  system = system;
                  config.allowUnfree = true;
                };
                nixos-2505 = import inputs.nixos-2505 {
                  system = system;
                  config.allowUnfree = true;
                };
              };
            }

            # load module defitions
            inputs.home-manager.nixosModules.home-manager
            inputs.nvf.nixosModules.default

            ./hosts/${hostname}/configuration.nix
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
