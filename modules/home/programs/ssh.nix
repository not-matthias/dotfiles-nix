{...}: {
  home.file.".ssh/sockets/.keep".text = "";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = true;
    matchBlocks."*" = {
      compression = true;
      addKeysToAgent = "yes";
      controlMaster = "auto";
      controlPath = "~/.ssh/sockets/%r@%h:%p";
      controlPersist = "10m";
      hashKnownHosts = true;
    };
    extraConfig = ''
      StrictHostKeyChecking accept-new
    '';
  };
}
