# Troubleshooting

[Back to the overview](../README.md)

## Cached evaluation failures

After fixing the underlying configuration error, bypass a cached failure when building Framework with `sudo nixos-rebuild build --flake .#framework --option eval-cache false`.

Use the matching target for another host. This bypasses the evaluation cache; it does not fix a failing expression or package build.

## Quickshell session failures

The [Quickshell service](../modules/home/programs/quickshell/default.nix) starts with `graphical-session.target` and stops with it through `PartOf`. It should not run against a closed Wayland socket after logout.

Inspect the user service with `systemctl --user status quickshell` and `journalctl --user -u quickshell -b`. Check `systemctl --user status graphical-session.target` before investigating the bar itself. Avoid adding a separate compositor-startup restart that competes with the service lifecycle.

## Missing battery widget

The [battery component](../modules/home/programs/quickshell/config/Components/Battery/Battery.qml) uses UPower and hides itself unless the display device is ready, present, and a laptop battery. A hidden widget is expected on machines without a battery.

The [Niri module](../modules/system/desktop/niri/default.nix) enables UPower. On a laptop, check `systemctl status upower` and `journalctl --user -u quickshell -b`. Rebuild and activate after changing the system configuration.

## Timeguard recovery

The [Timeguard integration](../modules/system/services/timeguard.nix) configures `timeguard-guard.target` to start at boot, with `Upholds=timeguard.service` to bring the service back after a stop. It sets `RefuseManualStop=true` on both units. Runtime overrides can change these settings; even when enforced, they add friction, not protection against unrestricted root access.

Inspect unit files and drop-ins with `systemctl cat timeguard.service timeguard-guard.target`, then check the loaded settings with `systemctl show timeguard.service timeguard-guard.target -p Id -p RefuseManualStop -p Upholds`. Runtime drop-ins under `/run/systemd/system/<unit>.d/` can override stop protection and restart behavior. Review each override before removing it. After intended changes, reload systemd with `sudo systemctl daemon-reload` and start the guard with `sudo systemctl start timeguard-guard.target`.
