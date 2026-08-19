# Flat view of the shared skill tree, for every agent's skills root.
#
# Skill scanners are non-recursive: only `<root>/<name>/SKILL.md` is discovered. The tree in
# ./skills is grouped by category (`coding/`, `third-party/<author>/`), so each group sits one
# level too deep. Expose a farm of symlinks instead, one entry per skill:
#
#   $out/code-style   -> <store>/coding/code-style
#   $out/agent-browser -> <store>/third-party/vercel-labs/agent-browser
#
# Targets are absolute so the links survive being copied into home-manager's file tree, which
# preserves symlinks verbatim rather than following them.
#
# Two skills sharing a directory name would shadow each other in every agent, so let `ln -s`
# fail the build instead of silently picking one.
{
  lib,
  pkgs,
}: let
  src = ./skills;
  # Relative path of every directory containing SKILL.md, at any depth.
  findSkills = dir: rel:
    lib.flatten (lib.mapAttrsToList (
      name: type: let
        rel' =
          if rel == ""
          then name
          else "${rel}/${name}";
      in
        if type != "directory"
        then []
        else if builtins.pathExists (dir + "/${name}/SKILL.md")
        then [rel']
        else findSkills (dir + "/${name}") rel'
    ) (builtins.readDir dir));
in
  pkgs.runCommand "agent-skills-flat" {} ''
    mkdir $out
    ${lib.concatMapStrings (
      path: "ln -s ${src}/${path} $out/${baseNameOf path}\n"
    ) (findSkills src "")}
  ''
