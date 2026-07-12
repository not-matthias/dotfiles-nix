{
  config,
  unstable,
  ...
}: {
  stylix.targets.vscode.enable = false;

  programs.vscode = {
    package = unstable.vscode;
    mutableExtensionsDir = true;
    profiles.default = {
      enableUpdateCheck = false;
      userSettings =
        builtins.fromJSON (builtins.readFile ./settings.json)
        // {
          "workbench.colorTheme" =
            if (config.stylix.polarity or "light") == "dark"
            then "Dark 2026"
            else "Light 2026";
        };
      keybindings = builtins.fromJSON (builtins.readFile ./keybindings.json);
      userMcp = builtins.fromJSON (builtins.readFile ./mcp.json);
    };
  };
}
