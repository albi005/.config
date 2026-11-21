# Native Nix build for alb1.hu (.NET 10 Blazor Server)
#
# Regenerate NuGet lockfile after dependency changes:
#   $(nix build --no-link --print-out-paths ./nixos#alb1.fetch-deps) ./nixos/pkgs/alb1.hu/deps.json
{
  fetchFromGitHub,
  dotnetCorePackages,
  buildDotnetModule,
  openssl,
  icu,
}:
buildDotnetModule {
  pname = "alb1";
  version = "0.0.1-3beafac";

  src = fetchFromGitHub {
    owner = "albi005";
    repo = "alb1.hu";
    rev = "3beafaca860db4d504410c67ca2d20c72b037bf7";
    hash = "sha256-Shi4ew1zYlkuv5ohXiqOvu34c9SF4ujP4EuTQIgvgQY=";
  };

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

  meta.mainProgram = "Hello";
}
