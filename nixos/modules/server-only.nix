# Included by machines that are always-on servers (iron, slime).
# Don't import on machines also used as desktops.
{
  ...
}:
{
  # Don't run missed GC jobs immediately at boot on servers.
  nix.gc.persistent = false;

  # Allow root to inspect the local dotfiles git checkout if needed.
  programs.git.config.safe.directory = "/home/albi/.config";
}
