# https://github.com/wiltaylor/dotfiles/blob/175f6442f557066d2008fc4cf830efb2534c2d49/modules/hardware/firmware.nix#L10
{pkgs, ...}: {
  # Enable all unfree hardware support.
  # See: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
  hardware.firmware = with pkgs; [firmwareLinuxNonfree];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # Enable firmware update service
  services.fwupd = {
    enable = true;
    extraRemotes = [
      "lvfs-testing"
    ];
    uefiCapsuleSettings = {
      DisableCapsuleUpdateOnDisk = true;
    };
  };
}
