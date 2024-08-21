{
  pkgs,
  config,
  ...
}: let
  unstable =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      sha256 = "sha256:0awagdjzv2fsy5v7a0wxz1hd642gsglib2gk4lnqm0iybly7kf0s";
    }) {
      system = "x86_64-linux";

      config = {
        allowUnfree = true;
      };
    };
  # unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in {
  environment.systemPackages = with pkgs; [
    unstable.ollama
  ];

  services.ollama = {
    enable = true;
    package = unstable.ollama;
    # host = "0.0.0.0";
    # port = 11434;
  };

  services.open-webui = {
    enable = true;
    # host = "0.0.0.0";
    port = 11435;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
    };
  };
}
