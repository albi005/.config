{ lib
, fetchFromGitHub
, fetchurl
, nixosTests
, stdenv
, dotnetCorePackages
, buildDotnetModule
, ffmpeg
, fontconfig
, freetype
, jellyfin-web
, sqlite
, libspatialite
}:

buildDotnetModule rec {
  pname = "dishelps";
  version = "10.8.10"; # ensure that jellyfin-web has matching version

  src = /home/albi/src/DisHelps;

  patches = [
  ];

  propagatedBuildInputs = [
    sqlite
  ];

  projectFile = "DisHelps.Web/DisHelps.Web.csproj";
  executables = [ "DisHelps.Web" ];
  nugetDeps = ./deps.nix;
  runtimeDeps = [
    ffmpeg
    fontconfig
    freetype
    libspatialite
  ];
  dotnet-sdk = dotnetCorePackages.sdk_7_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_7_0;
  dotnetBuildFlags = [ "--no-self-contained" ];
  # buildType = "Debug";

  # preInstall = ''
  #   makeWrapperArgs+=(
  #     --add-flags "--ffmpeg ${ffmpeg}/bin/ffmpeg"
  #     --add-flags "--webdir ${jellyfin-web}/share/jellyfin-web"
  #   )
  # '';

  # passthru.tests = {
  #   smoke-test = nixosTests.jellyfin;
  # };
  #
  # passthru.updateScript = ./update.sh;
  #
  # meta = with lib; {
  #   description = "The Free Software Media System";
  #   homepage = "https://jellyfin.org/";
  #   # https://github.com/jellyfin/jellyfin/issues/610#issuecomment-537625510
  #   license = licenses.gpl2Plus;
  #   maintainers = with maintainers; [ nyanloutre minijackson purcell jojosch ];
  #   platforms = dotnet-runtime.meta.platforms;
  # };
}
