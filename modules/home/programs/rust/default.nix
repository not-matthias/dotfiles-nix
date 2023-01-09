{pkgs, ...}: let
  rustToolchain =
    pkgs.fenix.complete.withComponents
    [
      "cargo"
      "clippy"
      "llvm-tools-preview"
      "rust-analyzer-preview"
      "rust-src"
      "rust-std"
      "rustc"
      "rustfmt"
    ];
in {
  home = {
    packages = with pkgs; [
      bintools
      clang
      lldb
      mold

      rustToolchain
      pkgs.fenix.targets."wasm32-unknown-unknown".latest.rust-std
      pkgs.fenix.targets."x86_64-pc-windows-gnu".latest.rust-std
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
    alias = {
      b = "build";
      c = "check";
      t = "test";
      r = "run";
      rr = "run --release";
      br = "build --release";
    };
  };
}
