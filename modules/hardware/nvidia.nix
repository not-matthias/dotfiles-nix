{config, ...}: let
  nvidia_x11 = config.boot.kernelPackages.nvidiaPackages.legacy_470;
in {
  services.xserver.videoDrivers = ["nvidia"];
  boot.blacklistedKernelModules = ["nouveau"];
  hardware = {
    nvidia = {
      package = nvidia_x11;
      modesetting.enable = true;
      nvidiaPersistenced = true;
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };
}
