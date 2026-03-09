{
  pkgs,
  lib,
  ...
}: let
  version = "release-20260302-1";
  idaVersion = "9.3";
  platform = "x86_64-linux-built_on_ubuntu_24.04";

  bindiffSrc = pkgs.fetchurl {
    url = "https://github.com/Lil-Ran/build-bindiff-for-ida-9/releases/download/${version}/BinDiff-IDA_${idaVersion}-${platform}.zip";
    sha256 = "0s9hw1j43dnzarw2bswwx8nbya28gp3bdghxhg5jrabaqhmdjpc8";
  };

  binexportSrc = pkgs.fetchurl {
    url = "https://github.com/Lil-Ran/build-bindiff-for-ida-9/releases/download/${version}/BinExport-IDA_${idaVersion}-${platform}.zip";
    sha256 = "08b5hwg16xd0619d6485yjsqfk325325q3sf40c5j9n7ya3q926d";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "bindiff-ida";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = [pkgs.unzip pkgs.patchelf];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/plugins

      unzip ${bindiffSrc} -d bindiff
      unzip ${binexportSrc} -d binexport

      cp bindiff/ida/bindiff8_ida64.so $out/plugins/
      cp binexport/ida/binexport12_ida64.so $out/plugins/

      # Set RPATH so the plugins find libida64.so in the parent directory
      # (IDA's install dir) at runtime.
      for f in $out/plugins/*.so; do
        patchelf --set-rpath '$ORIGIN/..' "$f"
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "BinDiff and BinExport IDA Pro 9.x plugins";
      homepage = "https://github.com/Lil-Ran/build-bindiff-for-ida-9";
      license = licenses.asl20;
      platforms = ["x86_64-linux"];
    };
  }
