{
  config,
  domain,
  flakes,
  lib,
  user,
  ...
}: {
  config = lib.mkMerge [
    {
      home-manager.users.${user} = {
        config,
        lib,
        osConfig,
        pkgs,
        ...
      }: {
        imports = [flakes.taskwarrior-web.homeManagerModules.default];

        config = lib.mkIf config.programs.taskwarrior.enable {
          services.taskwarrior-web.enable = osConfig.networking.hostName == "pc";
          systemd.user.services.taskwarrior-web.Service.Environment =
            lib.mkIf (osConfig.networking.hostName == "pc")
            (lib.mkAfter [
              "ORIGIN=https://todo.${domain}"
              "TASKWARRIOR_WEB_ALLOWED_HOST=todo.${domain}"
            ]);
          programs.cli-agents.programSkills.taskwarrior = ./cli-agents/shared/program-skills/taskwarrior;

          home.packages = with pkgs; [
            tasksh
            taskwarrior-tui
            timewarrior
            timew-sync-client
          ];

          programs.taskwarrior = {
            package = pkgs.taskwarrior3;
            config = {
              sync.server.url = "https://todo-sync.pcnm.duckdns.org";
              sync.server.client_id = "7af28379-c8aa-468e-8b9a-949021609eb7";

              # General configuration
              data.location = "~/.task";
              confirmation = false;
              report.next.filter = "status:pending -WAITING";
              report.next.columns = "id,start.age,depends,priority,project,tag,recur,scheduled.countdown,due.relative,until.remaining,description,urgency";
              report.next.labels = "ID,Active,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg";

              # Urgency configuration
              urgency.uda.priority.H.coefficient = 6.0;
              urgency.uda.priority.M.coefficient = 3.9;
              urgency.uda.priority.L.coefficient = 1.8;

              # Timewarrior integration
              alias.start = "execute timew start";
              alias.stop = "execute timew stop";

              # Syncall integration UDAs
              uda.gcalid.type = "string";
              uda.gcalid.label = "Google Calendar ID";
              uda.gtasksid.type = "string";
              uda.gtasksid.label = "Google Tasks ID";
              uda.notionid.type = "string";
              uda.notionid.label = "Notion ID";
            };
            extraConfig = "include /run/agenix/taskchampion-sync";
          };

          programs.fish.shellAbbrs = {
            # Task management
            "t" = "task";
            "ta" = "task add";
            "tl" = "task list";
            "tn" = "task next";
            "td" = "task done";
            "tm" = "task modify";
            "ts" = "task summary";
            "tp" = "task projects";

            # Context switching
            "tcf" = "task context fitness";
            "tcl" = "task context life";
            "tch" = "task context home-server";
            "tcd" = "task context dotfiles";
            "tcw" = "task context work";
            "tcle" = "task context learning";
            "tcn" = "task context none";
            "tcx" = "task context list";

            # Timewarrior
            "tw" = "timew";
            "tws" = "timew start";
            "twst" = "timew stop";
            "twsu" = "timew summary";
            "twl" = "timew";

            # Syncall integrations
            "sg" = "tw_gtasks_sync"; # Google Tasks sync
            "sc" = "tw_gcal_sync"; # Google Calendar sync
            "sn" = "tw_notion_sync"; # Notion sync
            "sa" = "syncall"; # Main syncall command
          };
        };
      };
    }
    (lib.mkIf config.home-manager.users.${user}.services.taskwarrior-web.enable {
      networking.hosts."127.0.0.1" = ["todo.${domain}"];

      services.caddy.virtualHosts."todo.${domain}".extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:3000
      '';
    })
  ];
}
