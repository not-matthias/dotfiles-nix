{...}: {
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  # `earlyoom` notifications require `systembus-notify`, and setting it
  # explicitly avoids conflicting upstream defaults when other modules, such as
  # `smartd`, keep their own default disabled.
  services.systembus-notify.enable = true;
}
