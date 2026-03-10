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
    pkgs.helix # neovim but rust (actually goated)
    pkgs.vscode-json-languageserver
    pkgs.yaml-language-server
    pkgs.elixir-ls
    inputs.wakatime-ls.packages."${pkgs.stdenv.hostPlatform.system}".default # coding-time tracker language-server for helix
    nixos-unstable.helm-ls
    pkgs.vhdl-ls # Very High Speed Integrated Circuit Hardware Description Language
  ];
}
