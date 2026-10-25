{...}: {
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    # User services inherit a higher oom_score_adj than memory-heavy jobs.
    # Select the largest resident process instead of killing the user bus first.
    # Match /proc/PID/comm, including Nix-wrapped and truncated QEMU names.
    extraArgs = [
      "--sort-by-rss"
      "--ignore"
      "^(niri|helium|[.]?qemu-system-.*)$"
    ];
  };

  # `earlyoom` notifications require `systembus-notify`, and setting it
  # explicitly avoids conflicting upstream defaults when other modules, such as
  # `smartd`, keep their own default disabled.
  services.systembus-notify.enable = true;
}
