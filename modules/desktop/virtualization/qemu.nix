{
  pkgs,
  user,
  ...
}: {
  users.groups.libvirtd.members = ["root" "${user}"];
  virtualisation = {
    lxc.enable = true;
    lxd.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        runAsRoot = false;
        ovmf.enable = true;
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
      qemu_kvm
      OVMF
      gvfs # Used for shared folders between linux and windows
    ];
  };

  services = {
    # Enable file sharing between OS
    gvfs.enable = true;
  };
}
