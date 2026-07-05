{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "shortcut-history";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  meta = with lib; {
    description = "Privacy-preserving shortcut history aggregator for evdev key combos (daily aggregate counts only)";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "shortcut-history";
  };
}
