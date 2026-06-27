{
  description = "Albi's nix config";

  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-2505.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-2605.url = "github:NixOS/nixpkgs/nixos-26.05";

    # checks for unsaved or uncommitted changes
    git-leave.url = "github:mrnossiom/git-leave";
    git-leave.inputs.nixpkgs.follows = "nixos-unstable";

    # Using Nix, configure stuff that goes into your /home.
    # Option search: https://home-manager-options.extranix.com/
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixos-2605";

    # nix-based theming https://nix-community.github.io/stylix/installation.html#nixos
    stylix.url = "github:nix-community/stylix/release-26.05";
    stylix.inputs.nixpkgs.follows = "nixos-2605";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixos-unstable";

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
        inputs.nixos-2605.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [

            # set up dependency injection for module parameters.
            # use "inputs", "nixos-unstable", "nixos-2505", etc. in a module's parameter object
            {
              _module.args = {
                inputs = inputs;
                nixos-unstable = import inputs.nixos-unstable {
                  system = system;
                  config = {
                    allowUnfree = true;
                    android_sdk.accept_license = true;
                  };
                };
                nixos-2505 = import inputs.nixos-2505 {
                  system = system;
                  config = {
                    allowUnfree = true;
                    android_sdk.accept_license = true;
                  };
                };
                nixos-2511 = import inputs.nixos-2511 {
                  system = system;
                  config = {
                    allowUnfree = true;
                    android_sdk.accept_license = true;
                  };
                };
              };
            }

            # load module defitions
            inputs.home-manager.nixosModules.home-manager
            inputs.stylix.nixosModules.stylix
            inputs.nvf.nixosModules.default

            # apply host-specific entry-point module
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
      packages.${system} = {
        modelsim = pkgs.callPackage ./pkgs/modelsim { };
        quartus-ii-13_1 = pkgs.callPackage ./pkgs/quartus-ii-13_1 { };
        kcl-language-server = pkgs.callPackage ./pkgs/kcl-language-server { };
      };

      nixosConfigurations = {
        iron = mkHost "iron";
        netherite = mkHost "netherite";
        redstone = mkHost "redstone";
        slime = mkHost "slime";
        water = mkHost "water";
      };
    };
}
