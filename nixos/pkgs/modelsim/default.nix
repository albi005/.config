{
  lib,
  stdenv,
  buildFHSEnv,
  writeShellScript,
  fetchurl,
  patchelf,
}:

let
  # ModelSim 20.1 ships 32-bit (i386) binaries, so all runtime libraries
  # must be their 32-bit variants.  buildFHSEnv takes care of providing
  # a /lib/ld-linux.so.2 and a conventional filesystem the binaries expect.
  #
  # IMPORTANT: runtimeLibs must use explicit pkgs.* references (not `with`)
  # because buildFHSEnv calls multiPkgs with pkgsi686Linux, and `with`
  # in Nix does NOT shadow lexically-bound variables from outer scopes.

  modelsim-unwrapped = stdenv.mkDerivation rec {
    pname = "modelsim";
    version = "20.1.1.720";

    src = fetchurl {
      url = "https://downloads.intel.com/akdlm/software/acdsinst/20.1std.1/720/ib_installers/ModelSimSetup-${version}-linux.run";
      hash = "sha256-kUyRbya2uIZEAagvfa5Z2SCU86vQp7CJRurhbTraD7M=";
    };

    nativeBuildInputs = [ patchelf ];

    dontUnpack = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      # The installer is a 64-bit dynamically linked ELF that expects
      # /lib64/ld-linux-x86-64.so.2.  We must patch its interpreter
      # so it can execute inside the Nix build sandbox.
      install -m755 $src installer.run
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" installer.run

      # Run the installer in unattended mode
      ./installer.run \
        --mode unattended \
        --installdir "$out" \
        --accept_eula 1 \
        --modelsim_edition modelsim_ase

      # Remove the uninstaller and logs — not useful in Nix
      rm -rf "$out/uninstall" "$out/logs"

      runHook postInstall
    '';

    meta = with lib; {
      description = "ModelSim - Intel FPGA Starter Edition HDL simulator";
      homepage = "https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/model-sim.html";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };

  # Runtime library dependencies for ModelSim.
  # This function receives either the native pkgs (for targetPkgs) or
  # pkgsi686Linux (for multiPkgs).  We use explicit pkgs.attr access
  # instead of `with pkgs;` to ensure the correct package set is used.
  runtimeLibs = pkgs: [
    pkgs.glibc
    pkgs.gcc.cc.lib # libstdc++, libgcc_s
    pkgs.zlib
    pkgs.libxml2
    pkgs.libx11
    pkgs.libxext
    pkgs.libxft
    pkgs.libxrender
    pkgs.fontconfig
    pkgs.freetype
    pkgs.ncurses5
    pkgs.libxcrypt-legacy # libcrypt.so.1
    pkgs.libuuid
    pkgs.libxi
    pkgs.libxmu
    pkgs.libxt
    pkgs.libxcursor
    pkgs.libxrandr
    pkgs.libxfixes
    pkgs.libsm
    pkgs.libice
    pkgs.glib
  ];

in
buildFHSEnv {
  name = "modelsim";
  version = modelsim-unwrapped.version;

  targetPkgs = runtimeLibs;

  # multiArch provides 32-bit libraries alongside 64-bit ones,
  # which is required because all ModelSim binaries are i386.
  multiArch = true;
  multiPkgs = runtimeLibs;

  runScript = writeShellScript "modelsim-wrapper" ''
    base="${modelsim-unwrapped}/modelsim_ase"

    if [ $# -eq 0 ] || [ "$1" = "vsim" ]; then
      exec "$base/bin/vsim" "''${@:2}"
    else
      cmd="$1"
      shift
      if [ -x "$base/bin/$cmd" ]; then
        exec "$base/bin/$cmd" "$@"
      else
        echo "Unknown ModelSim command: $cmd" >&2
        echo "Available commands:" >&2
        ls "$base/bin/" >&2
        exit 1
      fi
    fi
  '';

  extraInstallCommands = ''
        # Create individual wrapper scripts for each ModelSim tool
        # so users can call them directly (e.g., vsim, vcom, vlog)
        base="${modelsim-unwrapped}/modelsim_ase"

        for tool in $(ls "$base/bin/"); do
          if [ "$tool" != "." ] && [ "$tool" != ".." ]; then
            cat > "$out/bin/$tool" <<WRAPPER
    #!/bin/sh
    exec "$out/bin/modelsim" "$tool" "\$@"
    WRAPPER
            chmod +x "$out/bin/$tool"
          fi
        done
  '';

  meta = modelsim-unwrapped.meta;
}
