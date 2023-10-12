let
  pkgs = import <nixpkgs> { };
in
{
  alb1 = pkgs.callPackage ./alb1.hu { };
  dishelps-fromsrc = pkgs.callPackage ./dishelps-fromsrc { };
  dishelps-patchelf = pkgs.callPackage ./dishelps-patchelf { };
  menza = pkgs.callPackage ./menza { };
  keletikuria = pkgs.callPackage ./keletikuria { };
}
