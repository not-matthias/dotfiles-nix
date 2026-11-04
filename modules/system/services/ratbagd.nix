{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.services.ratbagd.enable {
    # Release 0.18 lacks G502 X PLUS wireless IDs and profile/LED quirks.
    services.ratbagd.package = lib.mkDefault (pkgs.libratbag.overrideAttrs {
      version = "0.18-unstable-2026-09-17";
      src = pkgs.fetchFromGitHub {
        owner = "libratbag";
        repo = "libratbag";
        rev = "8235b5bb6032dea15901ab58a8218956f4494d08";
        hash = "sha256-0uRBbVI5GrXyUUvDlpa2w5djyRWMbl6rzpdOWR2TkPg=";
      };
    });

    # Piper 0.8 lacks the G502 X PLUS diagram and wireless button mappings.
    environment.systemPackages = [
      (pkgs.piper.overrideAttrs {
        version = "0.8-unstable-2026-08-12";
        src = pkgs.fetchFromGitHub {
          owner = "libratbag";
          repo = "piper";
          rev = "5d3c8845b55643595ccb8029dfa5c7a2fb079e77";
          hash = "sha256-oGa0NXgoiVYadCAB5cnQYrjh3KIVWhTxsSYaB4TVZSA=";
        };
      })
    ];
  };
}
