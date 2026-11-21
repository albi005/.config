# Native Nix build and NixOS service for alb1.hu (.NET 10 Blazor Server)
{
  pkgs,
  ...
}:
let
  alb1 = pkgs.buildDotnetModule {
    pname = "alb1";
    version = "0.0.1-3beafac";

    src = pkgs.fetchFromGitHub {
      owner = "albi005";
      repo = "alb1.hu";
      rev = "3beafaca860db4d504410c67ca2d20c72b037bf7";
      hash = "sha256-Shi4ew1zYlkuv5ohXiqOvu34c9SF4ujP4EuTQIgvgQY=";
    };

    projectFile = "Hello/Hello.csproj";
    dotnet-sdk = pkgs.dotnetCorePackages.sdk_10_0;
    dotnet-runtime = pkgs.dotnetCorePackages.aspnetcore_10_0;
    executables = [ "Hello" ];

    nugetDeps = map pkgs.fetchNuGet [
      {
        pname = "Blazored.LocalStorage";
        version = "4.5.0";
        hash = "sha256-0vklTFHEGgNG8V6ivQictuooyiXS2nMn/qLpfYhEBlE=";
      }
      {
        pname = "HtmlAgilityPack";
        version = "1.11.65";
        hash = "sha256-aZ8l3RbcCqI918whQuMktbdGGAo0/P4Mj5ywyrX/Klc=";
      }
      {
        pname = "OpenTelemetry";
        version = "1.14.0";
        hash = "sha256-nspJW+N+4P+9F8wwpCtJgFovPeInveotw7CAYfP3MN4=";
      }
      {
        pname = "OpenTelemetry.Api";
        version = "1.14.0";
        hash = "sha256-Dn8gWzYyFQuNjP1m6YJzSrPetF+G+R+zVFEJevFSv+c=";
      }
      {
        pname = "OpenTelemetry.Api.ProviderBuilderExtensions";
        version = "1.14.0";
        hash = "sha256-1jbbubCLqiw5f+QzpjMdGtKeNU57hQUTxvKPZck/5Pk=";
      }
      {
        pname = "OpenTelemetry.Exporter.OpenTelemetryProtocol";
        version = "1.14.0";
        hash = "sha256-bHwqcxT4FWXlfmVlq3ztFrzJB98tcmFkZ2xL8uCXuSA=";
      }
      {
        pname = "OpenTelemetry.Extensions.Hosting";
        version = "1.14.0";
        hash = "sha256-cIbpTokrkIFc4R3PmOFn5B/zR/FWW4Gy6/c003GfY8M=";
      }
      {
        pname = "OpenTelemetry.Instrumentation.AspNetCore";
        version = "1.14.0";
        hash = "sha256-v93jmSUWGQjENx14eUlCMLEV8x8SaES73bpUkOr3qtU=";
      }
      {
        pname = "OpenTelemetry.Instrumentation.Http";
        version = "1.14.0";
        hash = "sha256-FzOu1W8Ox8MAUhv1KrwQ7w5PAAQKGTdzB0F51y390ag=";
      }
      {
        pname = "OpenTelemetry.Instrumentation.Runtime";
        version = "1.14.0";
        hash = "sha256-ShkIVKcGbBTkuz319ffZKag7PmVWwGVwLfrhYB+pkM4=";
      }
    ];

    # ASP.NET Core serves wwwroot relative to DOTNET_CONTENTROOT.
    makeWrapperArgs = [
      "--set"
      "DOTNET_CONTENTROOT"
      "${placeholder "out"}/lib/alb1"
    ];

    runtimeDeps = [
      pkgs.openssl
      pkgs.icu
    ];

    meta.mainProgram = "Hello";
  };
in
{
  systemd.tmpfiles.rules = [
    # Ensure the read-only bind target exists under ProtectSystem="strict".
    "d /alb1.hu_files 0755 root root -"
  ];

  systemd.services.alb1 = {
    description = "alb1.hu";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      ASPNETCORE_URLS = "http://127.0.0.1:10001";
      ASPNETCORE_ENVIRONMENT = "Production";
      DOTNET_gcServer = "0"; # keep RAM usage within MemoryMax
      HOME = "/var/lib/alb1"; # persist ASP.NET Core DataProtection keys
      OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317";
      # "Logging__LogLevel__Microsoft.AspNetCore.HttpLogging.HttpLoggingMiddleware" = "Warning";
    };
    serviceConfig = {
      ExecStart = "${alb1}/bin/Hello";
      User = "alb1";
      Group = "alb1";
      StateDirectory = "alb1";
      StateDirectoryMode = "0700";
      Restart = "on-failure";
      RestartSec = "5s";
      MemoryMax = "512M";
      BindReadOnlyPaths = [ "/home/albi/alb1.hu_files:/alb1.hu_files" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
    };
  };

  users.users.alb1 = {
    group = "alb1";
    isSystemUser = true;
  };
  users.groups.alb1 = { };
}
