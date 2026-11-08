{
  config,
  flakes,
  lib,
  pkgs,
  ...
}: let
  kernel = flakes.win11-kvm.packages.${pkgs.stdenv.hostPlatform.system}.kernel;
  cachedKernel = kernel.override {
    stdenv = pkgs.ccacheStdenv.override {
      inherit (kernel) stdenv;
      extraConfig = ''
        export CCACHE_DIR=${lib.escapeShellArg config.programs.ccache.cacheDir}
        export CCACHE_MAXSIZE=20G
        export CCACHE_COMPRESS=1
        export CCACHE_UMASK=007
        export CCACHE_SLOPPINESS=random_seed
      '';
    };
  };
in {
  programs.ccache.enable = true;
  nix.settings = {
    cores = 0;
    max-jobs = 1;
    extra-sandbox-paths = [config.programs.ccache.cacheDir];
  };

  # Override the lab module's forced kernel without dropping its patches.
  specialisation.windows-vfio.configuration.boot.kernelPackages =
    lib.mkOverride 40 (pkgs.linuxPackagesFor cachedKernel);
}
