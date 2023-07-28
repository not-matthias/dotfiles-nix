# References:
# - https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
# - https://looking-glass.io/wiki/Troubleshooting
{user, ...}: {
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ${user} kvm -"
  ];
}
