{
  pkgs,
  lib,
  guest,
  devices,
  services,
  kernelModules,
}: let
  forEach = xs: f: lib.concatMapStringsSep "\n" f xs;
  nodedev = address: "pci_" + builtins.replaceStrings [":" "."] ["_" "_"] address;
  preflight = ''
        configured_iommu_group=""
        for address in ${lib.concatMapStringsSep " " lib.escapeShellArg devices}; do
          iommu_group_link="/sys/bus/pci/devices/$address/iommu_group"
          if [ ! -e "$iommu_group_link" ]; then
            printf 'single-gpu-passthrough: PCI device %s has no available IOMMU group\n' "$address" >&2
            exit 1
          fi
          if ! iommu_group_path=$(readlink -f -- "$iommu_group_link") || [ ! -d "$iommu_group_path" ]; then
            printf 'single-gpu-passthrough: cannot resolve IOMMU group for PCI device %s\n' "$address" >&2
            exit 1
          fi
          if [ -z "$configured_iommu_group" ]; then
            configured_iommu_group="$iommu_group_path"
          elif [ "$configured_iommu_group" != "$iommu_group_path" ]; then
            printf 'single-gpu-passthrough: configured PCI devices do not share an IOMMU group\n' >&2
            exit 1
          fi
        done

        if [ -z "$configured_iommu_group" ] || [ ! -d "$configured_iommu_group/devices" ]; then
          printf 'single-gpu-passthrough: IOMMU group device list is unavailable\n' >&2
          exit 1
        fi
        for address in ${lib.concatMapStringsSep " " lib.escapeShellArg devices}; do
          if [ ! -e "$configured_iommu_group/devices/$address" ]; then
            printf 'single-gpu-passthrough: PCI device %s is missing from its IOMMU group device list\n' "$address" >&2
            exit 1
          fi
        done
        for member_path in "$configured_iommu_group"/devices/*; do
          if [ ! -e "$member_path" ]; then
            printf 'single-gpu-passthrough: IOMMU group contains an unavailable device entry\n' >&2
            exit 1
          fi
          member_address="''${member_path##*/}"
          case "$member_address" in
    ${forEach devices (address: "        ${lib.escapeShellArg address}) ;;")}
            *)
              printf 'single-gpu-passthrough: IOMMU group contains unconfigured PCI device %s\n' "$member_address" >&2
              exit 1
              ;;
          esac
        done
  '';
  detach = ''
    ${forEach services (unit: "systemctl stop ${lib.escapeShellArg unit}")}
    for vtcon in /sys/class/vtconsole/vtcon*/bind; do
      [ -e "$vtcon" ] && echo 0 > "$vtcon"
    done
    if [ -e /sys/bus/platform/drivers/efi-framebuffer/efi-framebuffer.0 ]; then
      echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
    fi
    ${forEach kernelModules (mod: "modprobe -r ${lib.escapeShellArg mod}")}
    modprobe vfio-pci
    ${forEach devices (address: "virsh nodedev-detach ${lib.escapeShellArg (nodedev address)}")}
  '';
  reattach = ''
    ${forEach devices (address: "virsh nodedev-reattach ${lib.escapeShellArg (nodedev address)} || failed=1")}
    ${forEach (lib.reverseList kernelModules) (mod: "modprobe ${lib.escapeShellArg mod} || failed=1")}
    if [ -e /sys/bus/platform/devices/efi-framebuffer.0 ]; then
      echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind || failed=1
    fi
    for vtcon in /sys/class/vtconsole/vtcon*/bind; do
      if [ -e "$vtcon" ]; then
        echo 1 > "$vtcon" || failed=1
      fi
    done
    ${forEach (lib.reverseList services) (unit: "systemctl start ${lib.escapeShellArg unit} || failed=1")}
  '';
in
  pkgs.writeShellScript "single-gpu-passthrough" ''
    export PATH="$PATH:${lib.makeBinPath [pkgs.coreutils pkgs.kmod pkgs.systemd pkgs.libvirt]}"
    set -euE

    [ "''${1:-}" = ${lib.escapeShellArg guest} ] || exit 0

    reattach() {
      local failed=0
      ${reattach}
      return "$failed"
    }

    case "''${2:-}/''${3:-}" in
      prepare/begin)
        ${preflight}
        # libvirt does not run release/end when prepare fails.
        trap 'trap - ERR; reattach; exit 1' ERR
        ${detach}
        trap - ERR
        ;;
      release/end)
        reattach
        ;;
    esac
  ''
