{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.maki;
  # maki dynamic provider for the umans-local proxy. umans-local speaks the
  # Anthropic Messages API at http://127.0.0.1:8084/v1/messages. maki's
  # anthropic base uses `resolve.base_url` as the full request URL and injects
  # `anthropic-version` itself, so only the key header is needed. No interactive
  # auth flow exists (dummy key), hence has_auth=false; `resolve` is always
  # called regardless.
  #
  # GLM-5.2 is listed first in the strong tier: maki uses the first model per
  # tier for sub-agents.
  umansLocalProvider = pkgs.writeShellScript "umans-local" ''
    case "$1" in
      info)
        printf '%s\n' '{"display_name":"Umans Local","base":"anthropic","has_auth":false}'
        ;;
      models)
        printf '%s\n' '[
          {"id":"umans-glm-5.2","tier":"strong","context_window":405504,"max_output_tokens":131071,"supports_thinking":true,"supports_vision":true},
          {"id":"umans-kimi-k2.7","tier":"strong","context_window":262144,"max_output_tokens":32768,"supports_thinking":true,"supports_vision":true},
          {"id":"umans-coder","tier":"medium","context_window":262144,"max_output_tokens":32768,"supports_thinking":true,"supports_vision":true},
          {"id":"umans-qwen3.6-35b-a3b","tier":"medium","context_window":262144,"max_output_tokens":32768,"supports_thinking":true,"supports_vision":true},
          {"id":"umans-flash","tier":"weak","context_window":262144,"max_output_tokens":32768,"supports_thinking":true,"supports_vision":true}
        ]'
        ;;
      resolve|refresh|reload)
        printf '%s\n' '{"base_url":"http://127.0.0.1:8084/v1/messages","headers":{"x-api-key":"dummy"}}'
        ;;
      login|logout) exit 0 ;;
      *) exit 1 ;;
    esac
  '';
in {
  options.programs.cli-agents.maki = {
    enable = mkEnableOption "maki CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.maki];

    home.file = {
      ".config/maki/init.lua".text = ''
        maki.setup({
            always_yolo = true,
            provider = {
                default_model = "umans-local/umans-glm-5.2",
            },
        })

      '';
      ".config/maki/providers/umans-local".source = umansLocalProvider;
      ".config/maki/AGENTS.md".source = ../shared/AGENTS.md;
    };
  };
}
