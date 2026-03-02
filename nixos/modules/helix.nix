{
  lib,
  pkgs,
  nixos-unstable,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.helix # neovim but rust (actually goated)
    pkgs.vscode-json-languageserver # json ls for helix
    pkgs.yaml-language-server # for helix
    pkgs.elixir-ls # used by helix
    inputs.wakatime-ls.packages."${pkgs.stdenv.hostPlatform.system}".default # coding-time tracker language-server for helix
    nixos-unstable.helm-ls # for helix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      helix = prev.helix.overrideAttrs (old: {
        # Any helix-specific overrides here
      });
    })
  ];
}
