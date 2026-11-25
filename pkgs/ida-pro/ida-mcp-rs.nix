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
    version = "9.4.4";

    src = pkgs.fetchFromGitHub {
      owner = "blacktop";
      repo = "ida-mcp-rs";
      rev = "v9.4.4";
      hash = "sha256-wiaShiZJo0euTRQTQd8i+xeC7tMT+R1I/K93fnY2Mbk=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-+8y13HMaMf2cuASxj+kTH59a+5iM+afgLXZjg2B+D0s=";

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
