{ ... }:
{
  # enable settings required by IntelliJ Profiler
  boot.kernel.sysctl = {
    # Allow broader access to performance monitoring events (adjust as needed)
    # Level 1: Allows kernel profiling for users with CAP_SYSLOG.
    "kernel.perf_event_paranoid" = "1"; # Or -1 for unrestricted access

    # Allow exposure of kernel addresses via /proc (needed by some profiling tools)
    "kernel.kptr_restrict" = "0";
  };
}
