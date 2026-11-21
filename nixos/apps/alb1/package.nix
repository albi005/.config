# Native Nix package for alb1.hu (.NET 10 Blazor Server)
#
# Regenerate NuGet lockfile after dependency changes:
#   nix run ./nixos#alb1.fetch-deps ./nixos/apps/alb1/deps.json
{
  lib,
  pkgs,
  buildDotnetModule,
  dotnetCorePackages,
  openssl,
  icu,
}:
let
  pins = import ../../lib/pins.nix { inherit lib pkgs; };
  pin = pins.readAppPin ./pin.json;
in
buildDotnetModule {
  pname = "alb1";
  version = pin.version;

  inherit (pin) src;

  projectFile = "Hello/Hello.csproj";
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  executables = [ "Hello" ];

  # ASP.NET Core serves wwwroot relative to DOTNET_CONTENTROOT.
  makeWrapperArgs = [
    "--set"
    "DOTNET_CONTENTROOT"
    "${placeholder "out"}/lib/alb1"
  ];

  runtimeDeps = [
    openssl
    icu
  ];

  meta = {
    description = "alb1.hu personal website";
    homepage = "https://alb1.hu";
    mainProgram = "Hello";
  };
}
