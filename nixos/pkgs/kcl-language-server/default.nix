{
  fetchFromGitHub,
  kcl,
  lib,
  pkg-config,
  protobuf,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kcl-language-server";
  version = "0.12.3";

  src = fetchFromGitHub {
    owner = "kcl-lang";
    repo = "kcl";
    rev = "e2f5adca6d6291824a6377e2a8b2b6ed35775b29";
    hash = "sha256-oPgdYos//Bm0e9piwwMEvvMg+V1hidE6JxcM/ALzuek=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  env = {
    PROTOC = "${protobuf}/bin/protoc";
    PROTOC_INCLUDE = "${protobuf}/include";
  };

  buildAndTestSubdir = "crates/tools/src/LSP";

  buildPhaseCargoFlags = [
    "--profile"
    "release"
    "--offline"
  ];

  nativeBuildInputs = [
    pkg-config
    protobuf
  ];

  doCheck = false;

  meta = {
    changelog = "https://github.com/kcl-lang/kcl/releases/tag/v${finalAttrs.version}";
    description = "High-performance implementation of KCL written in Rust that uses LLVM as the compiler backend";
    downloadPage = "https://github.com/kcl-lang/kcl/tree/${finalAttrs.src.rev}/crates/tools/src/LSP";
    homepage = "https://www.kcl-lang.io/";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = kcl.meta.maintainers;
    mainProgram = "kcl-language-server";
  };
})
