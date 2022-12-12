{pkgs, ...}: {
  # TODO:
  # https://github.com/KubqoA/dotfiles/blob/bc8aec4fb033740ffedf61b8580577902c156d6b/modules/services/onedrive.nix
  # Run with:
  # `onedrive --monitor`
  # systemctl --user enable onedrive                                                                                                          deadnix
  # systemctl --user start onedrive

  home.packages = [
    pkgs.onedrive
  ];

  home.file.".config/onedrive/config".text = ''
    sync_dir = "/mnt/data/onedrive"
  '';
}
