{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "bindiff-ida";
  version = "8";

  src = pkgs.fetchurl {
    url = "https://github.com/google/bindiff/releases/download/v8/bindiff_8_amd64.deb";
    sha256 = "1njd5w4mymxy9rms0xyplmmjgb46ai40wdwl6xrzd7aajzir06c2";
  };

  nativeBuildInputs = [pkgs.dpkg pkgs.autoPatchelfHook];

  buildInputs = with pkgs; [
    stdenv.cc.cc
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    dpkg-deb -x $src unpacked
    mkdir -p $out/plugins

    # Copy the IDA Pro plugin .so files.
    cp unpacked/opt/bindiff/plugins/idapro/bindiff8_ida.so   $out/plugins/
    cp unpacked/opt/bindiff/plugins/idapro/bindiff8_ida64.so $out/plugins/
    cp unpacked/opt/bindiff/plugins/idapro/binexport12_ida.so   $out/plugins/
    cp unpacked/opt/bindiff/plugins/idapro/binexport12_ida64.so $out/plugins/

    runHook postInstall
  '';

  meta = with lib; {
    description = "BinDiff IDA Pro plugin for binary diffing";
    homepage = "https://github.com/google/bindiff";
    license = licenses.asl20;
    platforms = ["x86_64-linux"];
  };
}
