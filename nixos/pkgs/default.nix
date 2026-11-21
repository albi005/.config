let
  pkgs = import <nixpkgs> { };
in
{
  dishelps-fromsrc = pkgs.callPackage ./dishelps-fromsrc { };
  dishelps-patchelf = pkgs.callPackage ./dishelps-patchelf { };
  menza = pkgs.callPackage ./menza { };
  keletikuria = pkgs.callPackage ./keletikuria { };
}
