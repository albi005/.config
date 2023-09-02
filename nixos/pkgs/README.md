```
$ nix-build -A alb1.fetch-deps
/nix/store/i3wp37nvdazgpk5hl53hwzhs82pzzh01-fetch-alb1.hu-deps
$ /nix/store/i3wp37nvdazgpk5hl53hwzhs82pzzh01-fetch-alb1.hu-deps
Succesfully wrote lockfile to /home/albi/.config/nixos/pkgs/alb1.hu/deps.nix
```

## Problemos

- menza: 
```
$ nix-build -A menza
/nix/store/igwf7hm6cjdcl0mac0n2rpmq47ssil6k-dotnet-sdk-7.0.306/sdk/7.0.306/Sdks/Microsoft.NET.Sdk/targets/Microsoft.NET.Sdk.FrameworkReferenceResolution.targets(135,5):
error NETSDK1084:
There is no application host available for the specified RuntimeIdentifier 'browser-wasm'.
[/build/source/Menza.Client/Menza.Client.csproj]
```
