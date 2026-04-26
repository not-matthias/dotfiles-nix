{unstable, ...}: {
  stylix.targets.zed.enable = false;

  programs.zed-editor = {
    enable = true;
    package = unstable.zed-editor;
    mutableUserSettings = true;
    mutableUserKeymaps = true;

    # userSettings = lib.mkForce (builtins.fromJSON (builtins.readFile ./settings.json));
    # userKeymaps = builtins.fromJSON (builtins.readFile ./keymaps.json);
  };
}
