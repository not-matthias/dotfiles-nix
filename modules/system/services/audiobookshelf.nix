{
  lib,
  config,
  ...
}: let
  cfg = config.services.audiobookshelf;
in {
  options.services.audiobookshelf = {
    audioFolder = lib.mkOption {
      type = lib.types.str;
      description = "The path to the audio folder";
    };
  };

  config = lib.mkIf cfg.enable {
    services.audiobookshelf = {
      dataDir = "/var/lib/audiobookshelf";
      port = 8234;
    };

    fileSystems."/var/lib/audiobookshelf" = {
      device = cfg.audioFolder;
      options = ["bind" "perms=444"];
    };
  };
}
