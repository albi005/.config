# Helpers for consuming pinned apps (Nix or Dockerfile tarballs) and pinned
# 3rd-party OCI images without floating tags or manual container registries.
{
  lib,
  pkgs,
}:
let
  imagesFile = ../pins/images.json;
  imagePins = builtins.fromJSON (builtins.readFile imagesFile);
in
{
  # Return a digest-pinned OCI image reference from nixos/pins/images.json:
  #   "ghcr.io/matter-js/matterjs-server:stable@sha256:..."
  # Asserts that a sha256 digest is present so floating tags fail evaluation.
  imageRef =
    name:
    let
      pin = imagePins.${name} or (throw "Unknown image pin '${name}' in nixos/pins/images.json");
    in
    assert lib.assertMsg (lib.hasPrefix "sha256:" (
      pin.digest or ""
    )) "Image pin '${name}' in nixos/pins/images.json must have a sha256 digest";
    "${pin.repository}:${pin.tag}@${pin.digest}";

  # Read an app's pin.json and materialize its source or OCI tarball derivation.
  #
  # Supported kinds:
  #   - "nix": GitHub source pinned by rev + SRI hash (fetchFromGitHub)
  #   - "dockerfile": OCI tarball (.tar.gz / .tar.zst) pinned by url + SRI hash (fetchurl)
  readAppPin =
    pinPath:
    let
      pin = builtins.fromJSON (builtins.readFile pinPath);
      kind = pin.kind or (throw "${toString pinPath}: missing 'kind' ('nix' or 'dockerfile')");
    in
    if kind == "nix" then
      pin
      // {
        src = pkgs.fetchFromGitHub {
          inherit (pin)
            owner
            repo
            rev
            hash
            ;
        };
      }
    else if kind == "dockerfile" then
      assert lib.assertMsg (
        pin ? url && pin ? hash && pin ? image
      ) "${toString pinPath}: dockerfile pin requires 'url', 'hash', and 'image'";
      pin
      // {
        imageFile = pkgs.fetchurl {
          inherit (pin) url hash;
        };
      }
    else
      throw "${toString pinPath}: unsupported kind '${kind}' (expected 'nix' or 'dockerfile')";
}
