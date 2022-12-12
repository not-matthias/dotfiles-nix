# References:
# - https://discourse.nixos.org/t/libvirt-installing-qemu-hook/385/7 (libvirt hooks)
# - https://gitlab.com/risingprismtv/single-gpu-passthrough
# - https://github.com/viperML/dotfiles/blob/62fac868c54b471803f234d1eef8b76b3ed66ba0/modules/nixos/vfio/default.nix
# - https://www.youtube.com/watch?v=eTWf5D092VY
# - https://libreddit.northboot.xyz/r/VFIO/comments/p4kmxr/tips_for_single_gpu_passthrough_on_nixos/
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.single-gpu-passthrough;
  my-iommu-group = [
    "pci_0000_26_00_0"
    "pci_0000_26_00_1"
    "pci_0000_26_00_2"
    "pci_0000_26_00_3"
  ];
  my-kmods = [
    "nvidia_drm"
    "nvidia_modeset"
    "drm_kms_helper"
    "i2c_nvidia_gpu"
    "nvidia"
    "drm"
  ];

  qemuEntrypoint = pkgs.writeShellScript "qemu" ''
    # Author: Sebastiaan Meijer (sebastiaan@passthroughpo.st)
    export PATH="$PATH:${pkgs.findutils}/bin:${pkgs.bash}/bin:${pkgs.util-linux}/bin"

    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"
    MISC="''${@:4}"

    BASEDIR="$(dirname $0)"

    HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"

    set -e # If a script exits with an error, we should as well.

    # check if it's a non-empty executable file
    if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
        eval \"$HOOKPATH\" "$@"
    elif [ -d "$HOOKPATH" ]; then
        while read file; do
            # check for null string
            if [ ! -z "$file" ]; then
              # Log the hook execution
              mkdir -p /var/log/libvirt/hooks
              script /var/log/libvirt/hooks/$GUEST_NAME-$HOOK_NAME-$STATE_NAME.log bash -c "$file $@"
            fi
        done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
    fi
  '';
  hookPrepare = pkgs.writeShellScript "start.sh" ''
    export PATH="$PATH:${pkgs.kmod}/bin:${pkgs.systemd}/bin:${pkgs.libvirt}/bin"
    set -uxo pipefail
    echo $(date)

    # Stop display manager
    systemctl stop display-manager.service
    killall gdm-x-session

    # Stop all drivers
    sudo rmmod nvidia_drm
    sudo rmmod nvidia_uvm
    sudo rmmod nvidia_modeset
    sudo rmmod nvidia

    # Unbind VTconsoles
    echo 0 > /sys/class/vtconsole/vtcon0/bind
    echo 0 > /sys/class/vtconsole/vtcon1/bind

    # Unbind EFI Framebuffer
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
    sleep 2

    # Unload all Nvidia drivers
    ${lib.concatMapStringsSep "\n" (kmod: "modprobe -r ${kmod}") my-kmods}

    # Detach GPU devices from host
    ${lib.concatMapStringsSep "\n" (dev: "virsh nodedev-detach ${dev}") my-iommu-group}

    # Load vfio module
    modprobe vfio-pci
    modprobe vfio_pci
    modprobe vfio_iommu_type1
  '';
  hookRelease = pkgs.writeShellScript "stop.sh" ''
    export PATH="$PATH:${pkgs.kmod}/bin:${pkgs.systemd}/bin:${pkgs.libvirt}/bin"
    set -ux -o pipefail

    # Unload vfio module
    modprobe -r vfio-pci

    # Attach GPU devices from host
    ${lib.concatMapStringsSep "\n" (dev: "virsh nodedev-reattach ${dev}") my-iommu-group}

    # Load nvidia drivers (may not be needed)
    ${lib.concatMapStringsSep "\n" (kmod: "modprobe ${kmod}") my-kmods}

    # Bind EFI Framebuffer
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

    # Bind VTconsoles
    echo 1 > /sys/class/vtconsole/vtcon0/bind
    echo 1 > /sys/class/vtconsole/vtcon1/bind

    # Start display manager
    systemctl start display-manager.service
  '';
in {
  options.virtualisation.single-gpu-passthrough = {
    enable = lib.mkEnableOption "Single GPU Passthrough";
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "L+ /var/lib/libvirt/hooks/qemu - - - - ${qemuEntrypoint}"
      # "L+ /var/lib/libvirt/qemu/windows-nvidia.xml - - - - ${myPath}/modules/nixos/vfio/windows-nvidia.xml"
      "L+ /var/lib/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh - - - - ${hookPrepare}"
      "L+ /var/lib/libvirt/hooks/qemu.d/win10/release/end/stop.sh - - - - ${hookRelease}"
    ];
  };
}
