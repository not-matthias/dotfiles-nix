{...}: {
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    # User services inherit a higher oom_score_adj than memory-heavy jobs.
    # Select the largest resident process instead of killing the user bus first.
    # Protect the compositor and browser; earlyoom matches /proc/PID/comm.
    extraArgs = [
      "--sort-by-rss"
      "--ignore"
      "^(niri|helium)$"
    ];
  };

  # `earlyoom` notifications require `systembus-notify`, and setting it
  # explicitly avoids conflicting upstream defaults when other modules, such as
  # `smartd`, keep their own default disabled.
  services.systembus-notify.enable = true;
}
