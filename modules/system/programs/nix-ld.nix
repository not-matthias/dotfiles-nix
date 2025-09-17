{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.nix-ld;
in {
  config = lib.mkIf cfg.enable {
    # programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      acl
      attr
      bzip2
      dbus
      expat
      fontconfig
      freetype
      fuse3
      icu
      libnotify
      libsodium
      libssh
      libunwind
      libusb1
      libuuid
      nspr
      nss
      stdenv.cc.cc
      util-linux
      zlib
      zstd
      zlib-ng
    ];
  };
}
