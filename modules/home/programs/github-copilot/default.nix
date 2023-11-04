# Credits to hacker1024: https://github.com/not-matthias/dotfiles-nix/issues/23#issuecomment-1399395667
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    idea-copilot
  ];
  xdg.dataFile = let
    ideDataDirectories = with pkgs;
    with jetbrains; {
      "JetBrains/IntelliJIdea" = idea-ultimate;
      "JetBrains/CLion" = clion;
      "JetBrains/RustRover" = rust-rover;
    };
    copilotAgent = "${pkgs.idea-copilot}/bin/copilot-agent";
  in
    lib.mapAttrs' (name: package:
      lib.nameValuePair "${name}${
        lib.versions.majorMinor (lib.getVersion package)
      }/github-copilot-intellij/copilot-agent/bin/copilot-agent-linux" {
        source = copilotAgent;
        force = true;
      })
    ideDataDirectories;
}
