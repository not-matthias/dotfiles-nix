# Registers omp plugins (the npm-package-based `.local/share/omp/plugins/`
# mechanism, distinct from the `.omp/agent/extensions/` extensions) and
# exports the home.file entries needed to install them.
{
  pkgs,
  lib,
  flakes,
}: let
  plugins = {
    "omp-autoresearch" = {
      source = flakes.omp-autoresearch.packages.${pkgs.stdenv.hostPlatform.system}.omp-autoresearch;
    };
  };
in
  lib.foldlAttrs (
    acc: name: p:
      acc
      // {
        ".local/share/omp/plugins/node_modules/${name}".source = p.source;
      }
  ) {
    # omp-plugins.lock.json is intentionally NOT managed: it is runtime enable
    # state that omp rewrites on every plugin install/enable — a store-backed
    # symlink here makes every marketplace install fail with EACCES.
    # Specifiers point at the store paths the symlinks above already resolve to.
    # `npm:<name>` would make any later `omp plugin install` fail on a package
    # that was never published to the registry.
    ".local/share/omp/plugins/package.json".text = builtins.toJSON {
      name = "omp-plugins";
      private = true;
      dependencies = lib.mapAttrs (_: p: "file:${p.source}") plugins;
    };
  }
  plugins
