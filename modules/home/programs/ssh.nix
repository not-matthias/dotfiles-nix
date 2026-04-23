{...}: {
  home.file.".ssh/sockets/.keep".text = "";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      compression = true;
      addKeysToAgent = "yes";
      controlMaster = "auto";
      controlPath = "~/.ssh/sockets/%C";
      controlPersist = "10m";
      hashKnownHosts = true;
    };
    extraConfig = ''
      StrictHostKeyChecking accept-new
    '';
  };
}
