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
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "akiselev";
    repo = "ghidra-cli";
    rev = "10019ba1f3b54c9edcca8ec644a30e16fb7b7c79";
    hash = "sha256-B4bnOOFtEsckT5TOAmjbx5AkrdpjeA248G+BrDUHY88=";
  };

  cargoHash = "sha256-r8AvlTJQ+j5YoLGJe3xIA0q+DPDTMKfhlT+nwFfNsPw=";

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
