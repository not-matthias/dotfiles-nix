# Pi packages built from npm at Nix build time.
# These replace the runtime-installed "packages" from settings.json
# by providing local paths that pi can load directly.
{pkgs}: {
  pi-web-providers = pkgs.callPackage ./pi-web-providers.nix {};
  pi-agentic-compaction = pkgs.callPackage ./pi-agentic-compaction.nix {};
  pi-queue-picker = pkgs.callPackage ./pi-queue-picker.nix {};
  pi-amplike = pkgs.callPackage ./pi-amplike.nix {};
  pi-autoresearch = pkgs.callPackage ./pi-autoresearch.nix {};
}
