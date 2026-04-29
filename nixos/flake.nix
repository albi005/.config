{
  description = "albi's nix config";

  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-2505.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-t3code.url = "github:NixOS/nixpkgs?ref=pull/510466/merge";

    # checks for unsaved or uncommitted changes
    git-leave.url = "github:mrnossiom/git-leave";
    git-leave.inputs.nixpkgs.follows = "nixos-unstable";

    # Using Nix, configure stuff that goes into your /home.
    # Option search: https://home-manager-options.extranix.com/
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixos-2511";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixos-unstable";

    # nix-based neovim distro
    nvf.url = "github:NotAShelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixos-unstable";

    # https://github.com/NixOS/nixpkgs/pull/332296
    # https://github.com/sweenu/nixfiles/blob/eff799274616b1c9679cf6cb73f4640617b5a0b3/flake.nix#L82
    otbr.url = "github:NixOS/nixpkgs/pull/332296/head";

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
            # https://github.com/sweenu/nixfiles/blob/eff799274616b1c9679cf6cb73f4640617b5a0b3/flake.nix#L236
            "${inputs.otbr}/nixos/modules/services/home-automation/openthread-border-router.nix"

            ./hosts/${hostname}/configuration.nix
          ];
        };
    in
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixos-2511 {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system}.modelsim = pkgs.callPackage ./pkgs/modelsim { };

      nixosConfigurations = {
        iron = mkHost "iron";
        netherite = mkHost "netherite";
        redstone = mkHost "redstone";
        slime = mkHost "slime";
        water = mkHost "water";
      };
    };
}
