# Included by machines that are always-on servers (iron, slime).
# Don't import on machines also used as interactive desktops.
{
  ...
}:
{
  # Always-on servers deploy CI-gated `deploy/<hostname>` branches immediately
  # via comin (replacing the old local `system.autoUpgrade --recreate-lock-file`,
  # which compiled locally and drifted from flake.lock).
  albi.gitops.role = "server";

  # Allow root to inspect the local dotfiles checkout if needed during debugging.
  programs.git.config.safe.directory = "/home/albi/.config/.git";
}
