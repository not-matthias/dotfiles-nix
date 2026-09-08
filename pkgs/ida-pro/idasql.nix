{
  stdenv,
  lib,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  ida-pro,
  ...
}:
assert lib.versions.majorMinor ida-pro.version == "9.4";
  stdenv.mkDerivation rec {
    pname = "idasql";
    version = "0.0.18.1";

    src = fetchurl {
      url = "https://github.com/allthingsida/idasql/releases/download/v${version}/idasql-v${version}-ida94.zip";
      hash = "sha256-Wm8vFcZgT41U9RDOkqNeqT+6uaYWIVLnxWsY+Lzp6Mw=";
    };

    nativeBuildInputs = [
      unzip
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      ida-pro
      stdenv.cc.cc.lib
    ];

    dontUnpack = true;
    dontStrip = true;

    installPhase = ''
      mkdir -p $out/bin $out/libexec $out/lib/ida/plugins

      unzip -p $src idasql-v${version}-ida94/linux-x86_64/cli/idasql > $out/libexec/idasql
      chmod +x $out/libexec/idasql

      unzip -p $src idasql-v${version}-ida94/linux-x86_64/plugin/idasql.so > $out/lib/ida/plugins/idasql.so
      unzip -p $src idasql-v${version}-ida94/linux-x86_64/plugin/ida-plugin.json > $out/lib/ida/plugins/ida-plugin.json

      makeWrapper $out/libexec/idasql $out/bin/idasql \
        --set IDADIR ${ida-pro}/opt \
        --prefix LD_LIBRARY_PATH : ${ida-pro}/lib
    '';

    meta = {
      description = "SQL interface for IDA Pro databases";
      homepage = "https://github.com/allthingsida/idasql";
      downloadPage = "https://github.com/allthingsida/idasql/releases";
      license = {
        fullName = "LicenseRef-Human-Origin-Source-1.0";
        free = false;
        redistributable = true;
        url = "https://github.com/allthingsida/idasql/blob/main/LICENSE";
      };
      mainProgram = "idasql";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
