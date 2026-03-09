{
  pkgs,
  lib,
  ida-pro,
  ...
}: let
  idaDir = "${ida-pro}/opt";
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "ida-mcp-rs";
    version = "9.3.1";

    src = pkgs.fetchFromGitHub {
      owner = "blacktop";
      repo = "ida-mcp-rs";
      rev = "216a67786a7b7ca7d1b7c4808bce2a7a85393aa9";
      hash = "sha256-IFHx98ZsiaeDq/9o05cIjqBoUvtT99QG14qJkb9dPiQ=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-VkL8CiNnV2OfQ7DhT+yGF7HUtn88DojAoaMAO3c43jg=";

    nativeBuildInputs = with pkgs; [
      pkg-config
      llvmPackages.clang
      llvmPackages.libclang
      makeWrapper
    ];

    buildInputs = with pkgs; [
      openssl
    ];

    # idalib-build needs IDADIR to find libida.so and libidalib.so.
    IDADIR = idaDir;

    # bindgen needs libclang.
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

    # Allow duplicate symbols from autocxx-generated code.
    RUSTFLAGS = "-C link-arg=-Wl,--allow-multiple-definition";

    # The build links against IDA's libraries.
    preBuild = ''
      export LD_LIBRARY_PATH="${idaDir}:$LD_LIBRARY_PATH"
    '';

    postInstall = ''
      wrapProgram $out/bin/ida-mcp \
        --set IDADIR ${idaDir} \
        --prefix LD_LIBRARY_PATH : ${idaDir}
    '';

    # Tests require a running IDA instance.
    doCheck = false;

    meta = with lib; {
      description = "Headless IDA Pro MCP server written in Rust";
      homepage = "https://github.com/blacktop/ida-mcp-rs";
      license = licenses.mit;
      mainProgram = "ida-mcp";
      platforms = ["x86_64-linux"];
    };
  }
