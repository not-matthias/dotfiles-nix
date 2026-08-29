# Upstream awatcher subscribes to the compositor's effective idle state, which
# every idle inhibitor suppresses. The patch switches its Wayland idle watcher
# to the input-only notification so AFK events track physical input.
{awatcher}:
awatcher.overrideAttrs (old: {
  patches = (old.patches or []) ++ [./input-idle-notification.patch];
})
