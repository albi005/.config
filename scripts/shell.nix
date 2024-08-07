{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
    packages = [
        (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
            requests
            environs
            nbtlib
            tabulate
            debugpy
            flask
            pystemd
        ]))
    ];
    shellHook = ''
        #export 
    '';
}
