{   fetchFromGitHub
    , dotnetCorePackages
    , buildDotnetModule
    , openssl
    , icu
    , fetchurl
    , alsaLib
    , zlib
    , pulseaudio
    , autoPatchelfHook
    , stdenv
    , lib
    , lttng-ust
    , lttng-tools
    , lttng-ust_2_12
}:

stdenv.mkDerivation {
    pname = "dishelps";
    version = "0.0.1";

    src = /home/albi/www/DisHelps/bin;

    nativeBuildInputs = [
        autoPatchelfHook
    ];

    # https://discourse.nixos.org/t/building-asp-net-core-app-with-nix-serving-static-files/30810/4
    makeWrapperArgs = [
        "--set DOTNET_CONTENTROOT ${placeholder "out"}/lib/"
    ];

    buildInputs = [
        alsaLib
        openssl
        zlib
        pulseaudio
        icu
        lttng-ust
        lttng-tools
        lttng-ust_2_12
    ];

    installPhase = ''
        ls
        install -m755 -D DisHelps.Web $out/bin/DisHelps.Web
        rm DisHelps.Web
        cp -r * $out/bin
    '';

    runtimeDeps = [ openssl icu ];
}
