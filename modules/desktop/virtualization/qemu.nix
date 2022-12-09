# References:
# https://discourse.nixos.org/t/gpu-passthrough-shows-black-screen/17435
{
  pkgs,
  user,
  ...
}: {
  users.groups.libvirtd.members = ["root" "${user}"];
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        # verbatimConfig = ''
        #   nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
        # '';
        package = pkgs.qemu_kvm;
      };
    };
    spiceUSBRedirection.enable = true; # USB passthrough
  };

  environment = {
    systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      qemu
      OVMF
      gvfs # Used for shared folders between linux and windows
    ];
  };

  services = {
    # Enable file sharing between OS
    gvfs.enable = true;
  };
}
