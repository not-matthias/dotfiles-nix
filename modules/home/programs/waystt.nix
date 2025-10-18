{
  config,
  lib,
  pkgs,
  flakes,
  ...
}: {
  options.programs.waystt = {
    enable = lib.mkEnableOption "waystt speech-to-text";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakes.waystt.packages.${pkgs.system}.default;
      description = "The waystt package to use";
    };

    provider = lib.mkOption {
      type = lib.types.enum ["openai" "google" "local"];
      default = "local";
      description = "Transcription provider to use";
    };

    whisperModel = lib.mkOption {
      type = lib.types.str;
      default = "ggml-base.en.bin";
      description = ''
        Whisper model file to use for local transcription.
        Available models:
        - ggml-tiny.en.bin (39 MB, fastest)
        - ggml-base.en.bin (142 MB, balanced, default)
        - ggml-small.en.bin (466 MB)
        - ggml-medium.en.bin (1.5 GB, more accurate)
        - ggml-large-v3.bin (2.9 GB, most accurate)
      '';
    };

    openaiApiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "OpenAI API key for cloud transcription";
    };

    enableAudioFeedback = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable beep sounds for recording start/stop";
    };

    beepVolume = lib.mkOption {
      type = lib.types.float;
      default = 0.1;
      description = "Volume for audio feedback beeps (0.0 to 1.0)";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      description = "Language code for transcription";
    };
  };

  config = lib.mkIf config.programs.waystt.enable {
    home.packages = [config.programs.waystt.package];

    xdg.configFile."waystt/.env".text = let
      cfg = config.programs.waystt;
    in ''
      # Transcription provider: openai, google, or local
      TRANSCRIPTION_PROVIDER=${cfg.provider}

      ${lib.optionalString (cfg.provider == "local") ''
        # Local Whisper model configuration
        WHISPER_MODEL=${cfg.whisperModel}
      ''}

      ${lib.optionalString (cfg.provider == "openai" && cfg.openaiApiKey != null) ''
        # OpenAI API configuration
        OPENAI_API_KEY=${cfg.openaiApiKey}
      ''}

      # Audio feedback settings
      ENABLE_AUDIO_FEEDBACK=${lib.boolToString cfg.enableAudioFeedback}
      BEEP_VOLUME=${toString cfg.beepVolume}

      # Language settings
      LANGUAGE=${cfg.language}
    '';

    # Create a systemd user service to download the model on first activation
    systemd.user.services.waystt-download-model = lib.mkIf (config.programs.waystt.provider == "local") {
      Unit = {
        Description = "Download Whisper model for waystt";
        ConditionPathExists = "!%h/.local/share/waystt/models/${config.programs.waystt.whisperModel}";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${config.programs.waystt.package}/bin/waystt --download-model";
        RemainAfterExit = true;
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
