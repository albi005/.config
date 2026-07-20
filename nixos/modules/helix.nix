{
  pkgs,
  nixos-unstable,
  inputs,
  ...
}:
{
  environment = {
    variables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };

  environment.systemPackages = [
    pkgs.bash-language-server
    pkgs.elixir-ls
    pkgs.helix # neovim but rust (actually goated)
    nixos-unstable.helm-ls
    pkgs.lua-language-server # hyprland config
    pkgs.protols # Protocol Buffers Language Server (.proto files)
    pkgs.typescript-language-server
    pkgs.vhdl-ls # Very High Speed Integrated Circuit Hardware Description Language
    pkgs.vscode-json-languageserver
    inputs.self.packages."${pkgs.stdenv.hostPlatform.system}".kcl-language-server
    inputs.wakatime-ls.packages."${pkgs.stdenv.hostPlatform.system}".default # coding-time tracker language-server for helix
    pkgs.yaml-language-server

    nixos-unstable.cue
  ];
}
