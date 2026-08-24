{
  pkgs,
  unstable,
  ...
}: {
  stylix.targets.vscode.enable = false;

  programs.vscode = {
    package = unstable.vscode;
    mutableExtensionsDir = false;
    profiles.default = {
      extensions = [
        (pkgs.vscode-utils.extensionFromVscodeMarketplace {
          name = "vscode-jetbrains-icon-theme";
          publisher = "chadalen";
          version = "2.40.0";
          hash = "sha256-xTnIkYtmHmytpE7uLNGIZizDpdOG4RSMBikOJK8F47k=";
        })
      ];
      enableUpdateCheck = false;
      userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
      keybindings = builtins.fromJSON (builtins.readFile ./keybindings.json);
      userMcp = builtins.fromJSON (builtins.readFile ./mcp.json);
    };
  };
}
