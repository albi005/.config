{
  pkgs ? import <nixpkgs> {},
}:
{
  rimshot = pkgs.fetchurl {
    url = "https://www.myinstants.com/media/sounds/rimshot.mp3";
    sha256 = "sha256-OxuZNSsVPAEvLRWhITlLUKdvIN2JAz9tTuBGLzKghzA=";
  };
  pipe = pkgs.fetchurl {
    url = "https://www.myinstants.com/media/sounds/metal-pipe-clang.mp3";
    sha256 = "sha256-afGFplWABZvSefrz78qLxm3KCphEc81al746O1s915c=";
  };
  vine = pkgs.fetchurl {
    url = "https://www.myinstants.com/media/sounds/vine-boom.mp3";
    sha256 = "sha256-xNrbwLnNIbExPsEYRaANlAG8IIrg9Z9UoCgrjLidVsI=";
  };
}
