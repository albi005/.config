{
  lib,
  stdenv,
  nodejs,
  importNpmLock,
  makeWrapper,
  autoPatchelfHook,
  git,
}:

let
  packageJson = lib.importJSON ./package.json;
  rawPackageLock = lib.importJSON ./package-lock.json;

  nodeOs = stdenv.hostPlatform.node.platform;
  nodeCpu = stdenv.hostPlatform.node.arch;
  nodeLibc = if stdenv.hostPlatform.isMusl then "musl" else "glibc";

  matchesConstraint =
    value: list:
    let
      positives = builtins.filter (x: !(lib.hasPrefix "!" x)) list;
      negatives = builtins.map (lib.removePrefix "!") (builtins.filter (lib.hasPrefix "!") list);
    in
    (positives == [ ] || builtins.elem value positives) && !(builtins.elem value negatives);

  matchesPlatform =
    pkg:
    (!(pkg ? os) || matchesConstraint nodeOs pkg.os)
    && (!(pkg ? cpu) || matchesConstraint nodeCpu pkg.cpu)
    && (!(pkg ? libc) || matchesConstraint nodeLibc pkg.libc);

  keptPackages = lib.filterAttrs (
    path: pkg: path == "" || matchesPlatform pkg
  ) rawPackageLock.packages;

  keptPackageNames = lib.mapAttrs' (
    path: _: lib.nameValuePair (lib.last (lib.splitString "node_modules/" path)) true
  ) (lib.filterAttrs (path: _: path != "") keptPackages);

  filteredPackageLock = rawPackageLock // {
    packages = lib.mapAttrs (
      _: pkg:
      pkg
      // lib.optionalAttrs (pkg ? optionalDependencies) {
        optionalDependencies = lib.filterAttrs (
          name: _: keptPackageNames ? ${name}
        ) pkg.optionalDependencies;
      }
    ) keptPackages;
  };

  nodeModules = importNpmLock.buildNodeModules {
    package = packageJson;
    packageLock = filteredPackageLock;
    inherit nodejs;
    derivationArgs = {
      pname = "deepseek-harness-node-modules";
      version = packageJson.version;
      npmFlags = [ "--ignore-scripts" ];
    };
  };
in
stdenv.mkDerivation {
  pname = "deepseek-harness";
  version = packageJson.version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isElf [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  # Some optional native prebuilds (e.g. non-Linux or optional backends) may reference
  # libraries that are not needed on this host; keep autoPatchelf strict first to inspect.
  installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/deepseek-harness $out/bin
        cp -r ${nodeModules}/node_modules $out/lib/deepseek-harness/node_modules
        chmod -R u+w $out/lib/deepseek-harness/node_modules

        # Restore executable bit on node-pty prebuilt spawn-helper (matches @deepseek-ai/dsh-subprocess-local postinstall)
        for helper in $out/lib/deepseek-harness/node_modules/node-pty/prebuilds/*/spawn-helper; do
          if [ -f "$helper" ]; then
            chmod 0755 "$helper"
          fi
        done

        # Remove non-host prebuilds inside node-pty so autoPatchelfHook does not choke on foreign arches
        if [ -d "$out/lib/deepseek-harness/node_modules/node-pty/prebuilds" ]; then
          for dir in "$out/lib/deepseek-harness/node_modules/node-pty/prebuilds"/*; do
            if [ "$(basename "$dir")" != "${nodeOs}-${nodeCpu}" ]; then
              rm -rf "$dir"
            fi
          done
        fi

        # Remove unused libc prebuilds (musl binaries on glibc hosts, or vice versa)
        ${lib.optionalString (!stdenv.hostPlatform.isMusl) ''
          rm -rf \
            $out/lib/deepseek-harness/node_modules/@koromix/koffi-*/musl_* \
            $out/lib/deepseek-harness/node_modules/@deepseek-ai/node-addon-system-*/bin/musl
        ''}
        ${lib.optionalString stdenv.hostPlatform.isMusl ''
          rm -rf \
            $out/lib/deepseek-harness/node_modules/@koromix/koffi-*/linux_* \
            $out/lib/deepseek-harness/node_modules/@deepseek-ai/node-addon-system-*/bin/glibc
        ''}

        # Patch node-addon-require-builtin to use Node's native --expose-internals when available.
        # Its native V8/x64 binary-disassembly fallback fails on NixOS's GCC-built Node.js binary.
        cat > $out/lib/deepseek-harness/node_modules/node-addon-require-builtin/lib/index.js <<'EOF'
    "use strict";
    const path = require("node:path");
    const { createEntryApi } = require("node-addon-native-custom-loader");
    let fallbackApi = null;
    function getFallbackApi() {
      if (!fallbackApi) {
        fallbackApi = createEntryApi(path.resolve(__dirname, ".."));
      }
      return fallbackApi;
    }
    function requireBuiltin(moduleId) {
      try {
        return require(moduleId);
      } catch {
        return getFallbackApi().requireBuiltin(moduleId);
      }
    }
    function isAllowedInternalId(moduleId) {
      return typeof moduleId === "string" && moduleId.startsWith("internal/");
    }
    function getBindingInfo() {
      return { mode: "expose-internals", product: "require-builtin", backend: "native" };
    }
    module.exports = {
      __esModule: true,
      requireBuiltin,
      isAllowedInternalId,
      getBindingInfo,
      default: { requireBuiltin, isAllowedInternalId, getBindingInfo },
    };
    EOF

        makeWrapper ${lib.getExe nodejs} $out/bin/dsh \
          --add-flags "--expose-internals $out/lib/deepseek-harness/node_modules/@deepseek-ai/dsh/lib/bin.js" \
          --prefix PATH : "${
            lib.makeBinPath [
              nodejs
              git
            ]
          }"

        runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness (dsh) open-source agent harness";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
