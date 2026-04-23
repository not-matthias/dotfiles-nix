{unstable, ...}: {
  stylix.targets.vscode.enable = false;

  programs.vscode = {
    package = unstable.vscode;
    mutableExtensionsDir = true;
    profiles.default = {
      enableUpdateCheck = false;
      # userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
      # keybindings = builtins.fromJSON (builtins.readFile ./keybindings.json);
      # userMcp = builtins.fromJSON (builtins.readFile ./mcp.json);
    };
  };
}
