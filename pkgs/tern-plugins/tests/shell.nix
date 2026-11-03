{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [python3 uv xvfb-run xdotool git];
  PYTEST_DISABLE_PLUGIN_AUTOLOAD = "1";
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [libxcb libxkbcommon libx11 libxcursor libxi libxrandr libxext vulkan-loader]);
  VK_DRIVER_FILES = "${pkgs.mesa}/share/vulkan/icd.d/lvp_icd.${pkgs.stdenv.hostPlatform.parsed.cpu.name}.json";
}
