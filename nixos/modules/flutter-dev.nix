{ nixos-unstable, ... }:
{
  environment = {
    systemPackages = [
      nixos-unstable.android-studio
      nixos-unstable.androidenv.androidPkgs.androidsdk
      nixos-unstable.dart
      nixos-unstable.flutter
      nixos-unstable.vscode
    ];
    variables = {
      FLUTTER_SDK = nixos-unstable.flutter;
    };
  };
}
