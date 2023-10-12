{   fetchFromGitHub
    , dotnetCorePackages
    , buildDotnetModule
    , openssl
    , icu
}:

buildDotnetModule {
    name = "KeletiKuria";

    src = fetchFromGitHub {
        owner = "albi005";
        repo = "KeletiKuria";
        rev = "main";
        sha256 = "sha256-p8BH3uX5XgM2swkpWNWbk5/3GbbSIyKWhWGnwgUY1+A=";
    };

    projectFile = "KeletiKuria/KeletiKuria.csproj";
    nugetDeps = ./deps.nix;
    dotnet-sdk = dotnetCorePackages.sdk_7_0;
    dotnet-runtime = dotnetCorePackages.runtime_7_0;
    # executables = [ "Hello" ];
    selfContainedBuild = true;

    # https://discourse.nixos.org/t/building-asp-net-core-app-with-nix-serving-static-files/30810/4
    makeWrapperArgs = [
        "--set DOTNET_CONTENTROOT ${placeholder "out"}/lib/"
    ];

    buildInputs = [ ];
    runtimeDeps = [ openssl icu ];
}
