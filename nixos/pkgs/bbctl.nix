{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.15.0";

  sources = {
    x86_64-linux = {
      url = "https://github.com/beeper/bridge-manager/releases/download/v${version}/bbctl-linux-amd64";
      hash = "sha256-/zCRgWQp1BrrUYcURfjM13hk6+R5pXpLSlmB/VBRpz4=";
    };
    aarch64-linux = {
      url = "https://github.com/beeper/bridge-manager/releases/download/v${version}/bbctl-linux-arm64";
      hash = "sha256-rqTxKawd/9lk0a2KV70tCAyWnyd2ZtCqc0tz3nxvADM=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "bbctl: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "bbctl";
  inherit version;

  src = fetchurl { inherit (source) url hash; };

  # The release binary is statically linked.
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/bbctl
    runHook postInstall
  '';

  meta = {
    description = "Beeper bridge manager (bbctl) for running self-hosted bridges";
    homepage = "https://github.com/beeper/bridge-manager";
    license = lib.licenses.mit;
    mainProgram = "bbctl";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames sources;
  };
}
