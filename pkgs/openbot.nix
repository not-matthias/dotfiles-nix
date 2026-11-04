{
  lib,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  buildFHSEnv,
}: let
  pname = "openbot";
  version = "0.61.0";
  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-Jt+/w49sOQN9H8k2Wv3TqXMDH2GX7y/hpnN0Bc2KO4U=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-NYINNSCaWRK9Y/IoDlSZ8cF3SjsKlEaUo8GGvDUbxbE=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system}
    or (throw "openbot: unsupported system ${stdenvNoCC.hostPlatform.system}");
  src = fetchurl {
    url = "https://github.com/nightly-labs/openbot/releases/download/v${version}/OpenBot-${version}-${source.arch}.AppImage";
    inherit (source) hash;
  };
  contents = appimageTools.extract {
    inherit pname version src;
    # Like upstream's Nix package, omit Sunshine's unavailable Ubuntu runtime dependencies.
    postExtract = ''
      rm -rf $out/resources/remote-desktop-runtime
    '';
  };
in
  buildFHSEnv (appimageTools.defaultFhsEnvArgs
    // {
      inherit pname version;
      targetPkgs = pkgs: appimageTools.defaultFhsEnvArgs.targetPkgs pkgs ++ [pkgs.libsecret pkgs.xdg-utils];
      # AppRun can silently add --no-sandbox; launch Electron directly to keep its sandbox.
      runScript = "${contents}/openbot";
      extraInstallCommands = ''
        install -Dm444 ${contents}/openbot.desktop "$out/share/applications/openbot.desktop"
        substituteInPlace "$out/share/applications/openbot.desktop" \
          --replace-fail 'Exec=AppRun %U' 'Exec=openbot %U'
        install -Dm444 ${contents}/openbot.png "$out/share/pixmaps/openbot.png"
      '';
      meta = {
        description = "Local-first desktop workspace for persistent AI teammates";
        longDescription = ''
          OpenBot runs coding agents in persistent local workspaces. Agents run
          without per-action approval after first-launch consent. This package
          keeps the Electron sandbox enabled and leaves updates to Nix.
          Remote desktop is unavailable, matching upstream's Nix package.
          Use is restricted to noncommercial purposes by the upstream license.
        '';
        homepage = "https://github.com/nightly-labs/openbot";
        changelog = "https://github.com/nightly-labs/openbot/releases/tag/v${version}";
        license = {
          shortName = "polyform-noncommercial";
          fullName = "PolyForm Noncommercial License 1.0.0";
          spdxId = "PolyForm-Noncommercial-1.0.0";
          url = "https://polyformproject.org/licenses/noncommercial/1.0.0/";
          free = false;
          redistributable = false;
        };
        platforms = builtins.attrNames sources;
        mainProgram = pname;
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
    })
