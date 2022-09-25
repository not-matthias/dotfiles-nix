{ pkgs, ... }: {
  nix = {
    extraOptions = ''
      extra-experimental-features = nix-command flakes
    '';
  };
}