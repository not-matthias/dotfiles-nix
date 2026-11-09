{...}: {
  home.file.".ssh/sockets/.keep".text = "";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      compression = true;
      addKeysToAgent = "yes";
      controlMaster = "auto";
      controlPath = "~/.ssh/sockets/%C";
      controlPersist = "10m";
      hashKnownHosts = true;
    };
    settings."boox boox.ide-snares.ts.net" = {
      HostName = "boox.ide-snares.ts.net";
      Port = 2222;
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };
    extraConfig = ''
      StrictHostKeyChecking accept-new
    '';
  };
}
