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
        # required for openssl
        perl
        gnumake

        bintools
        clang
        lldb
        mold

        # Cargo tools
        cargo-edit
        cargo-expand
        cargo-udeps
        #cargo-update
        cargo-sort
        cargo-criterion
        cargo-wipe

        (fenix.complete.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
          "rust-analyzer"
        ])
      ];

      sessionPath = [
        "$HOME/.cargo/bin"
      ];
    };

    home.file.".cargo/config.toml".source = (pkgs.formats.toml {}).generate "cargo-config" {
      # Fails with: `rustc: symbol lookup error: rustc: undefined symbol: _ZN3std2rt19lang_start_internal17h4172e5a0738dcd76E`
      # target.x86_64-unknown-linux-gnu = {
      #   rustflags = ["-C" "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"];
      # };
      build = {
        rustc-wrapper = "${pkgs.sccache}/bin/sccache";
      };
      alias = {
        b = "build";
        c = "check";
        t = "test";
        r = "run";
        rr = "run --release";
        br = "build --release";
      };
    };
  };
}
