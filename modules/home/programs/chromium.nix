{
  pkgs,
  flakes,
  lib,
  ...
}: let
  isX86 = pkgs.stdenv.hostPlatform.isx86_64;

  helium = flakes.custom-packages.packages.${pkgs.system}.helium;

  heliumWrapped =
    pkgs.runCommandLocal "helium-wrapped" {
      nativeBuildInputs = [pkgs.makeWrapper];
      meta = helium.meta or {};
    } ''
      mkdir -p $out/bin
      makeWrapper ${helium}/bin/helium $out/bin/helium \
        --add-flags "--no-default-browser-check --disable-breakpad"
      ln -s ${helium}/share $out/share
    '';
in {
  programs.chromium = {
    package =
      if isX86
      then heliumWrapped
      else pkgs.chromium;

    extensions = [
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      "nngceckbapebfimnlniiiahkandclblb"
      "dbepggeogbaibhgnhhndojpepiihcmeb"
      "hlepfoohegkhhmjieoechaddaejaokhf"
      "blaaajhemilngeeffpbfkdjjoefldkok"
      "mnjggcdmjocbbbhaepdhchncahnbgone"
      "edibdbjcniadpccecjdfdjjppcpchdlm"
      "eimadpbcbfnmbkopoojfekhnkhdbieeh"
      "dneaehbmnbhcippjikoajpoabadpodje"
      "hhinaapppaileiechjoiifaancjggfjm"
      "nglaklhklhcoonedhgnpgddginnjdadi"
    ];

    commandLineArgs = lib.optionals (!isX86) [
      "--no-default-browser-check"
      "--disable-breakpad"
    ];
  };
}
