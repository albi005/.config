{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  aiohttp,
  beautifulsoup4,
  requests,
}:

buildHomeAssistantComponent {
  owner = "rinyakok";
  domain = "idokep";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "rinyakok";
    repo = "homeassistant_idokep";
    rev = "1.1.2";
    hash = "sha256-SGlCgEm28+lnIKCPzou0pXCAb9eBJ7eoHxHXLNAv3TM=";
  };

  dependencies = [
    aiohttp
    beautifulsoup4
    requests
  ];

  dontCheckManifest = true;

  meta = with lib; {
    description = "Időkép weather data and forecast for Home Assistant";
    homepage = "https://github.com/rinyakok/homeassistant_idokep";
    license = licenses.mit;
  };
}
