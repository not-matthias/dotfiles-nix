{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  makeWrapper,
  ghidra,
  jdk21,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "ghidra-cli";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "akiselev";
    repo = "ghidra-cli";
    rev = "07b8d17c98f4aab2af4d26163ca25bfeda4471f1";
    hash = "sha256-bX+lT4YeBJkOLPW+db/4CCimnLUjdc6/REk5+5PtBEE=";
  };

  cargoHash = "sha256-J+XhpIo5T/6kotHH51XEyxYLVsjJ/+p0EXTKqhef/oc=";

  nativeBuildInputs = [pkg-config makeWrapper];
  buildInputs = [openssl];

  # Tests require a live Ghidra instance
  doCheck = false;

  # Rename to avoid conflict with the Ghidra GUI wrapper, then inject:
  #   GHIDRA_INSTALL_DIR  — points to the dir containing support/analyzeHeadless
  #   PATH                — prepend jdk21 so `java -version` works (ghidra-cli doctor check)
  postInstall = ''
    mv $out/bin/ghidra $out/bin/ghidra-cli
    wrapProgram $out/bin/ghidra-cli \
      --set GHIDRA_INSTALL_DIR "${ghidra}/lib/ghidra" \
      --prefix PATH : "${jdk21}/bin"
  '';

  meta = with lib; {
    description = "Rust CLI for headless Ghidra automation and AI agent integration";
    homepage = "https://github.com/akiselev/ghidra-cli";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "ghidra-cli";
  };
}
