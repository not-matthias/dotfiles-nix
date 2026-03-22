# TODO: Setup wild linker, see: https://github.com/davidlattimore/wild/blob/main/nix/nix.md
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.rust;
in {
  options.programs.rust = {
    enable = lib.mkEnableOption "rust";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # Required for rustup, otherwise we have linker errors:
        # https://github.com/NixOS/nixpkgs/issues/103642
        gcc
        rustup

        # Dependencies for building Rust packages
        pkg-config
        openssl
        zlib

        # Cargo tools
        cargo-edit
        cargo-expand
        cargo-udeps
        cargo-wipe
        cargo-nextest

        # (fenix.complete.withComponents [
        #   "cargo"
        #   "clippy"
        #   "rust-src"
        #   "rustc"
        #   "rustfmt"
        #   "rust-analyzer"
        # ])
      ];

      sessionPath = [
        "$HOME/.cargo/bin"
      ];
    };

    home.file.".cargo/config.toml".source = (pkgs.formats.toml {}).generate "cargo-config" {
      # Fails with: `rustc: symbol lookup error: rustc: undefined symbol: _ZN3std2rt19lang_start_internal17h4172e5a0738dcd76E`
      target.x86_64-unknown-linux-gnu = {
        # rustflags = ["-C" "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"];
        # rustflags = ["-Zthreads=8"];
        # rustflags = ["-Clink-arg=-fuse-ld=lld" "-Zthreads=8" "-Csymbol-mangling-version=v0"];
      };
      build = {
        # rustflags = ["-Clink-arg=-fuse-ld=lld" "-Zthreads=8" "-Csymbol-mangling-version=v0"];
        # rustc-wrapper = "${pkgs.sccache}/bin/sccache";
      };

      # unstable = {
      #   build-dir-new-layout = true;
      #   gc = true;
      #   gitoxide = true;
      #   mtime-on-use = true;
      #   checksum-freshness = true;
      #   fine-grain-locking = true;
      # };
      alias = {
        b = "build";
        c = "check";
        t = "nextest run";
        r = "run";
        rr = "run --release";
        br = "build --release";
      };
    };
  };
}
