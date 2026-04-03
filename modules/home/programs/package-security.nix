{...}: {
  # Minimum release age settings to avoid installing freshly-published
  # (potentially malicious) packages.
  # See: https://news.ycombinator.com/item?id=47582632

  # TODO: uv's exclude-newer requires an RFC 3339 date, not a relative duration.
  # xdg.configFile."uv/uv.toml".text = ''
  #   exclude-newer = "2026-03-26T00:00:00Z"
  # '';

  xdg.configFile."bun/bunfig.toml".text = ''
    minimumReleaseAge = 604800
  '';

  home.file.".npmrc".text = ''
    min-release-age=7
    ignore-scripts=true
  '';
}
