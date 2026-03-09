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

  nativeBuildInputs = [pkgs.dpkg pkgs.patchelf];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    dpkg-deb -x $src unpacked
    mkdir -p $out/plugins

    # Copy the IDA Pro plugin .so files and set RPATH so they find libida*.so
    # in the parent directory (IDA's install dir) at runtime.
    for f in bindiff8_ida.so bindiff8_ida64.so binexport12_ida.so binexport12_ida64.so; do
      cp "unpacked/opt/bindiff/plugins/idapro/$f" "$out/plugins/"
      patchelf --set-rpath '$ORIGIN/..' "$out/plugins/$f"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "BinDiff IDA Pro plugin for binary diffing";
    homepage = "https://github.com/google/bindiff";
    license = licenses.asl20;
    platforms = ["x86_64-linux"];
  };
}
