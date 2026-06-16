{pkgs}: let
  tomat = "${pkgs.tomat}/bin/tomat";

  # Left-click starts a session when idle, otherwise pauses/resumes.
  clickScript = pkgs.writeShellScriptBin "tomat-waybar-click" ''
    case "$(${tomat} status | ${pkgs.jq}/bin/jq -r .class)" in
      idle | "") exec ${tomat} start ;;
      *) exec ${tomat} toggle ;;
    esac
  '';
in {
  inherit clickScript;

  config = {
    "custom/tomat" = {
      return-type = "json";
      format = "{}";
      exec = "${tomat} status";
      interval = 1;
      on-click = "${clickScript}/bin/tomat-waybar-click";
      on-click-right = "${tomat} skip";
      on-click-middle = "${tomat} stop";
    };
  };

  style = ''
    #custom-tomat {
        padding: 3px 6px;
        background: transparent;
    }

    #custom-tomat.work {
        color: @base08;
    }

    #custom-tomat.break,
    #custom-tomat.long-break {
        color: @base0B;
    }

    #custom-tomat.work-paused,
    #custom-tomat.break-paused,
    #custom-tomat.long-break-paused {
        color: @base0A;
    }

    #custom-tomat.idle {
        color: @base03;
    }

    #custom-tomat:hover {
        background: rgba(255, 255, 255, 0.1);
        transition: all 0.3s ease-in-out;
    }
  '';
}
