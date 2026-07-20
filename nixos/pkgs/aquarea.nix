{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent {
  owner = "kamaradclimber";
  domain = "aquarea";
  version = "2.6.1";

  src = fetchFromGitHub {
    owner = "kamaradclimber";
    repo = "heishamon-homeassistant";
    rev = "2.6.1";
    hash = "sha256-gAw31/aJvvJ1PajeU6JtVtWS69BfJyIQuDf6fhMYQp0=";
  };

  meta = with lib; {
    description = "Home Assistant integration for heatpumps handled by HeishaMon";
    homepage = "https://github.com/kamaradclimber/heishamon-homeassistant";
    license = licenses.asl20;
  };
}
