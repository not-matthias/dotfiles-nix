# Pi packages built from npm at Nix build time.
# These replace the runtime-installed "packages" from settings.json
# by providing local paths that pi can load directly.
{pkgs}: {
  pi-web-providers = pkgs.callPackage ./pi-web-providers.nix {};
  # pi-goal = pkgs.callPackage ./pi-goal.nix {};  # replaced by pi-codex-goal extension
  # pi-agentic-compaction = pkgs.callPackage ./pi-agentic-compaction.nix {};
  pi-autoresearch = pkgs.callPackage ./pi-autoresearch.nix {};
  # pi-anthropic-oauth = pkgs.callPackage ./pi-anthropic-oauth.nix {};
  # pi-openai-server-compaction = pkgs.callPackage ./pi-openai-server-compaction.nix {};
}
