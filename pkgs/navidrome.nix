{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  ffmpeg-headless,
  ffmpegSupport ? true,
  plugins ? [],
}: let
  version = "0.64.2";
  sources = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-/dh/0QeBhmfCxQvCTcbOhWlix5WzgiqR+VwGbPrSxT4=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-bRaDQoy22ZzavD2oFblMwWHeWQSCATDFueLkLDTc2xU=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
  stdenvNoCC.mkDerivation {
    pname = "navidrome";
    inherit version;

    src = fetchurl {
      url = "https://github.com/navidrome/navidrome/releases/download/v${version}/navidrome_${version}_linux_${source.arch}.tar.gz";
      inherit (source) hash;
    };

    dontUnpack = true;
    dontStrip = true;
    nativeBuildInputs = lib.optional ffmpegSupport makeWrapper;

    installPhase = ''
      runHook preInstall
      tar -xzf "$src"
      install -Dm755 navidrome "$out/bin/navidrome"
      install -Dm444 LICENSE "$out/share/licenses/navidrome/LICENSE"
      mkdir -p "$out/share/plugins"
      ${lib.concatMapStringsSep "\n" (plugin: ''
          find ${plugin}/share/ -type f -name '*.ndp' \
            -exec ln -s {} "$out/share/plugins/${plugin.bundleName or plugin.pname}.ndp" \;
        '')
        plugins}
      runHook postInstall
    '';

    postFixup = lib.optionalString ffmpegSupport ''
      wrapProgram "$out/bin/navidrome" \
        --prefix PATH : ${lib.makeBinPath [ffmpeg-headless]}
    '';

    passthru = {inherit plugins;};

    meta = {
      description = "Music server and streamer compatible with Subsonic/Airsonic";
      homepage = "https://www.navidrome.org/";
      license = lib.licenses.gpl3Only;
      platforms = builtins.attrNames sources;
      mainProgram = "navidrome";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
