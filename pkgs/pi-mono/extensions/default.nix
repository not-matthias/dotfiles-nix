# Extension sources shared with oh-my-pi.
# Each entry has:
#   src       - the compiled extension source
#   resources - which resource directories to link (relative to src)
{pkgs}: let
  compileExtension = args: pkgs.callPackage ./compile-extension.nix args;
in {
  "docs-rs" = {
    src = compileExtension {src = ./custom/docs-rs;};
    resources.extensions = ".";
  };
}
