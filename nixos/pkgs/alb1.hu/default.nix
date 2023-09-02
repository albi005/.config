{   fetchFromGitHub
    , dotnetCorePackages
    , buildDotnetModule
    , openssl
    , icu
}:

buildDotnetModule {
    name = "alb1.hu";

    src = fetchFromGitHub {
        owner = "albi005";
        repo = "alb1.hu";
        rev = "main";
        sha256 = "sha256-p8BH3uX5XgMJswkpWNWbk5/FGbbSIyKWhWGnwgUY1+A=";
    };

    projectFile = "Hello/Hello.csproj";
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
