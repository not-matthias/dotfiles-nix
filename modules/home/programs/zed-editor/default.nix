{unstable, ...}: {
  stylix.targets.zed.enable = false;

  programs.zed-editor = {
    enable = true;
    package = unstable.zed-editor;
    mutableUserSettings = false;
    mutableUserKeymaps = false;
    userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
    userKeymaps = builtins.fromJSON (builtins.readFile ./keymaps.json);
  };
}
