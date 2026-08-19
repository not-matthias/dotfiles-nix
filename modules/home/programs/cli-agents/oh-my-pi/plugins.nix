# Registers omp plugins (the npm-package-based `.local/share/omp/plugins/`
# mechanism, distinct from the `.omp/agent/extensions/` extensions) and
# exports the home.file entries needed to install them.
{
  pkgs,
  lib,
}: let
  plugins = {
    "pi-autoresearch" = {
      version = "1.6.2";
      source = pkgs.fetchzip {
        url = "https://registry.npmjs.org/pi-autoresearch/-/pi-autoresearch-1.6.2.tgz";
        hash = "sha256-2xZpgtkCz9ITeU5/71nhiB2qnOEKvlxNxmDfCg2isXE=";
      };
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
    ".local/share/omp/plugins/package.json".text = builtins.toJSON {
      name = "omp-plugins";
      private = true;
      dependencies = lib.mapAttrs (name: _: "npm:${name}") plugins;
    };
    ".local/share/omp/plugins/omp-plugins.lock.json".text = builtins.toJSON {
      plugins =
        lib.mapAttrs (_: p: {
          version = p.version;
          enabledFeatures = null;
          enabled = true;
        })
        plugins;
      settings = {};
    };
  }
  plugins
