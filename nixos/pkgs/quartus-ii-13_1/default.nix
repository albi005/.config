{
  lib,
  stdenv,
  buildFHSEnv,
  fetchurl,
  makeDesktopItem,
  runCommand,
  runtimeShell,
  pkgsi686Linux,
}:

let
  version = "13.1.0.162";

  supportedDeviceArchive = fetchurl {
    url = "https://downloads.intel.com/akdlm/software/acdsinst/13.1/162/ib_installers/cyclone_web-${version}.qdz";
    hash = "sha1-g6XMjY1lGYu3gw7SLznNqGpwlEY=";
  };

  installer = fetchurl {
    url = "https://downloads.intel.com/akdlm/software/acdsinst/13.1/162/ib_installers/QuartusSetupWeb-${version}.run";
    hash = "sha256-XpUMuFTIWEukP+3mUM3tQOeVNPH6MbpDp+sY1h8Xe6k=";
  };

  runtimeLibs = pkgs: [
    pkgs.glib
    pkgs.xorg.libICE
    pkgs.xorg.libSM
    pkgs.xorg.libX11
    pkgs.xorg.libXau
    pkgs.xorg.libXcursor
    pkgs.xorg.libXdmcp
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXft
    pkgs.xorg.libXi
    pkgs.xorg.libXinerama
    pkgs.xorg.libXrandr
    pkgs.xorg.libXrender
    pkgs.xorg.libXt
    pkgs.bzip2
    pkgs.dbus
    pkgs.expat
    pkgs.fontconfig
    pkgs.freetype
    pkgs.glibc
    pkgs.gtk2
    pkgs.libpng
    pkgs.libpng12
    pkgs.libxcrypt-legacy
    pkgs.libxml2
    pkgs.ncurses5
    pkgs.zlib
  ];

  installEnv = buildFHSEnv {
    pname = "quartus-ii-13.1-install-env";
    inherit version;
    targetPkgs =
      pkgs:
      (runtimeLibs pkgs)
      ++ [
        (runCommand "ld-lsb-compat" { } ''
          mkdir -p "$out/lib"
          ln -sr "${pkgsi686Linux.glibc}/lib/ld-linux.so.2" "$out/lib/ld-lsb.so.3"
          ln -sr "${pkgs.glibc}/lib/ld-linux-x86-64.so.2" "$out/lib/ld-lsb-x86-64.so.3"
        '')
      ];
    multiArch = true;
    multiPkgs = runtimeLibs;
  };

  quartus-unwrapped = stdenv.mkDerivation {
    pname = "quartus-ii-web-edition-unwrapped";
    inherit version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      workdir="$PWD/quartus-installer"
      installroot="$PWD/quartus-installed"
      mkdir -p "$workdir"
      cp "${installer}" "$workdir/QuartusSetupWeb-${version}.run"
      cp "${supportedDeviceArchive}" "$workdir/cyclone_web-${version}.qdz"
      chmod +x "$workdir/QuartusSetupWeb-${version}.run"

      ${installEnv}/bin/quartus-ii-13.1-install-env -c "
        cd '$workdir'
        ./QuartusSetupWeb-${version}.run \
          --mode unattended \
          --unattendedmodeui none \
          --installdir '$installroot'
      "

      mkdir -p "$out"
      cp -a "$installroot"/. "$out"/

      rm -rf "$out/uninstall" "$out/logs"

      if [ -f "$out/quartus/adm/qenv.sh" ]; then
        substituteInPlace "$out/quartus/adm/qenv.sh" \
          --replace-fail 'grep sse /proc/cpuinfo > /dev/null 2>&1' ':'
      fi

      runHook postInstall
    '';

    meta = with lib; {
      description = "Intel Quartus II Web Edition 13.1 with Cyclone III/IV device support";
      homepage = "https://www.altera.com/downloads/fpga-development-tools/quartus-ii-web-edition-design-software-version-13-1-linux";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };

  desktopItem = makeDesktopItem {
    name = "quartus-ii-13.1";
    exec = "quartus";
    icon = "quartus";
    desktopName = "Quartus II 13.1";
    genericName = "FPGA Design Software";
    categories = [ "Development" ];
  };
in
buildFHSEnv rec {
  pname = "quartus-ii-13.1";
  inherit version;

  targetPkgs =
    pkgs:
    (runtimeLibs pkgs)
    ++ [
      (runCommand "ld-lsb-compat" { } ''
        mkdir -p "$out/lib"
        ln -sr "${pkgsi686Linux.glibc}/lib/ld-linux.so.2" "$out/lib/ld-lsb.so.3"
        ln -sr "${pkgs.glibc}/lib/ld-linux-x86-64.so.2" "$out/lib/ld-lsb-x86-64.so.3"
      '')
      pkgs.dejavu_fonts
      pkgs.gnumake
      pkgs.xorg.libXtst
    ];

  multiArch = true;
  multiPkgs = runtimeLibs;

  extraInstallCommands = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/64x64/apps
    ln -s ${desktopItem}/share/applications/* $out/share/applications
    if [ -f "${quartus-unwrapped}/quartus/adm/quartusii.png" ]; then
      ln -s ${quartus-unwrapped}/quartus/adm/quartusii.png $out/share/icons/hicolor/64x64/apps/quartus.png
    fi

    progs_to_wrap=(
      "${quartus-unwrapped}"/quartus/bin/*
      "${quartus-unwrapped}"/nios2eds/bin/*
    )

    wrapper=$out/bin/${pname}
    progs_wrapped=()
    for prog in ''${progs_to_wrap[@]}; do
      [ -e "$prog" ] || continue
      relname="''${prog#"${quartus-unwrapped}/"}"
      wrapped="$out/$relname"
      mkdir -p "$(dirname "$wrapped")"
      progs_wrapped+=("$wrapped")
      {
        echo "#!${runtimeShell}"
        echo "exec $wrapper $prog \"\$@\""
      } > "$wrapped"
    done

    chmod +x ''${progs_wrapped[@]}
    ln --symbolic --relative --target-directory "$out/bin" ''${progs_wrapped[@]}
  '';

  runScript = "";

  meta = quartus-unwrapped.meta // {
    mainProgram = "quartus";
  };
}
