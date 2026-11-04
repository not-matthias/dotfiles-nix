# Pi packages built from npm at Nix build time.
# These replace the runtime-installed "packages" from settings.json
# by providing local paths that pi can load directly.
{pkgs}: let
  compileExtension = pkgs.callPackage ../extensions/compile-extension.nix;
in {
  pi-web-access = compileExtension {
    src = pkgs.callPackage ./pi-web-access.nix {};
    entrypoints = ["index.ts"];
  };
  tintinweb-pi-subagents = compileExtension {
    src = pkgs.callPackage ./tintinweb-pi-subagents.nix {};
  };
}
