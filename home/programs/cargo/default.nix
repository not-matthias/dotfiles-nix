{config, ...}: {
  home.file.".cargo/config".source = config.lib.file.mkOutOfStoreSymlink ./config.toml;
}
