{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
    packages = [
        (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
            requests
            environs
        ]))
    ];
    shellHook = ''
        export OPEN_DEBUG_PATH=${pkgs.vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/OpenDebugAD7;
    '';
}
