{user, ...}: {
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["${user}"];

  nixpkgs.config.allowUnfree = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.x11 = true;
}
