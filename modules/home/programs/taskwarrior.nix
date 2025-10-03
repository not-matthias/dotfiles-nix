# docker run --init -d -p 3000:3000 -v ~/.task/:/app/taskdata/ -v ~/.taskrc:/app/.taskrc -v ~/.timewarrior/:/app/.timewarrior/ ghcr.io/tmahmood/taskwarrior-web:main
{pkgs, ...}: let
  # Use latest bugwarrior from develop branch for Python 3.13 compatibility
  bugwarrior = pkgs.python3Packages.buildPythonPackage rec {
    pname = "bugwarrior";
    version = "develop";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "ralphbean";
      repo = "bugwarrior";
      rev = "develop";
      sha256 = "sha256-e28E0lCNS4JN3i/l+zYzJOqaHz+buP0xtOyJND7ytJc=";
    };

    nativeBuildInputs = with pkgs.python3Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      click
      dogpile-cache
      jinja2
      lockfile
      pydantic
      python-dateutil
      pytz
      requests
      six
      taskw
      tomli
    ];

    doCheck = false; # Skip tests for now
  };
in {
  home.packages = with pkgs; [
    tasksh
    taskwarrior-tui
    timewarrior
    timew-sync-client
    bugwarrior
  ];

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      # Sync configuration
      taskd = {
        server = "taskwarrior.inthe.am:53589";
        credentials = "inthe_am/not-matthias/[UUID]";
        certificate = "~/.task/ca.cert.pem";
        key = "~/.task/private.key.pem";
        ca = "~/.task/ca.cert.pem";
      };

      # General configuration
      data.location = "~/.task";
      confirmation = false;
      report.next.filter = "status:pending -WAITING";
      report.next.columns = "id,start.age,depends,priority,project,tag,recur,scheduled.countdown,due.relative,until.remaining,description,urgency";
      report.next.labels = "ID,Active,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg";

      # UDA (User Defined Attributes)
      uda.reviewed.type = "date";
      uda.reviewed.label = "Reviewed";
      report._reviewed.description = "Tasksh review report.  Adjust the filter to your needs.";
      report._reviewed.columns = "uuid";
      report._reviewed.sort = "reviewed+,modified+";
      report._reviewed.filter = "( reviewed.none: or reviewed.before:now-6days ) and ( +PENDING or +WAITING )";

      # Urgency configuration
      urgency.user.project.Work.coefficient = 6.0;
      urgency.user.project.Personal.coefficient = 3.0;
      urgency.uda.priority.H.coefficient = 6.0;
      urgency.uda.priority.M.coefficient = 3.9;
      urgency.uda.priority.L.coefficient = 1.8;

      # Project contexts for quick switching
      context.fitness.read = "project:fitness";
      context.fitness.write = "project:fitness";
      context.life.read = "project:life";
      context.life.write = "project:life";
      context.home-server.read = "project:home-server";
      context.home-server.write = "project:home-server";
      context.dotfiles.read = "project:dotfiles";
      context.dotfiles.write = "project:dotfiles";
      context.work.read = "project:work";
      context.work.write = "project:work";
      context.learning.read = "project:learning";
      context.learning.write = "project:learning";

      # Timewarrior integration
      alias.start = "execute timew start";
      alias.stop = "execute timew stop";

      # Custom reports for better project management
      report.fitness.description = "Fitness related tasks";
      report.fitness.columns = "id,start.age,priority,description,urgency";
      report.fitness.labels = "ID,Active,P,Description,Urg";
      report.fitness.sort = "urgency-";
      report.fitness.filter = "project:fitness status:pending";

      report.projects.description = "Task count by project";
      report.projects.columns = "project,count";
      report.projects.labels = "Project,Count";
      report.projects.sort = "count-";
      report.projects.filter = "status:pending";

      # Todoist sync settings (for bugwarrior)
      uda.todoistid.type = "numeric";
      uda.todoistid.label = "Todoist ID";

      # Syncall integration UDAs
      uda.gcalid.type = "string";
      uda.gcalid.label = "Google Calendar ID";
      uda.gtasksid.type = "string";
      uda.gtasksid.label = "Google Tasks ID";
      uda.notionid.type = "string";
      uda.notionid.label = "Notion ID";

      # Linear-specific UDAs (for future Linear sync integration)
      uda.linearid.type = "string";
      uda.linearid.label = "Linear Issue ID";
      uda.linearurl.type = "string";
      uda.linearurl.label = "Linear Issue URL";
    };
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

    # Bugwarrior sync
    "bw" = "bugwarrior-pull";

    # Syncall integrations
    "sg" = "tw_gtasks_sync"; # Google Tasks sync
    "sc" = "tw_gcal_sync"; # Google Calendar sync
    "sn" = "tw_notion_sync"; # Notion sync
    "sa" = "syncall"; # Main syncall command
  };
}
