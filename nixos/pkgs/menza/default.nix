{   fetchFromGitHub
    , dotnetCorePackages
    , buildDotnetModule
    , openssl
    , icu
}:

buildDotnetModule {
    name = "menza";

    src = fetchFromGitHub {
        owner = "albi005";
        repo = "Menza";
        rev = "main";
        sha256 = "sha256-OxnGaNeacdDHzuaAFIKfYX0f4M7Ght5rWqhsldUTPYY=";
    };

    projectFile = "Menza.Server/Menza.Server.csproj";
    nugetDeps = ./deps.nix;
    dotnet-sdk = dotnetCorePackages.sdk_7_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_7_0;
    # executables = [ "Hello" ];
    selfContainedBuild = false;

    # https://discourse.nixos.org/t/building-asp-net-core-app-with-nix-serving-static-files/30810/4
    makeWrapperArgs = [
        "--set DOTNET_CONTENTROOT ${placeholder "out"}/lib/"
    ];

    buildInputs = [ ];
    runtimeDeps = [ openssl icu ];
}
