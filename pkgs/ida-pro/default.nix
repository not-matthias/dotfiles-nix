_self: super: {
  ida-sigmaker = super.callPackage ./ida-sigmaker.nix {};
  ida-guides = super.callPackage ./ida-guides.nix {};
  ida-wakatime = super.callPackage ./ida-wakatime.nix {};
  ida-codemode = super.callPackage ./ida-codemode.nix {};
  ida-domain = _self.ida-codemode.passthru.ida-domain;
  ida-nexus = super.callPackage ./ida-nexus.nix {
    inherit (_self) ida-domain;
  };
  ida-mcp = super.callPackage ./ida-mcp.nix {};
  bindiff-ida = super.callPackage ./bindiff.nix {};
  binsync-ida = super.callPackage ./binsync.nix {};
  ida-theme-explorer = super.callPackage ./ida-theme-explorer.nix {};
  headless-ida = super.callPackage ./headless-ida.nix {};
  ida-sdk-source = super.callPackage ./ida-sdk-source.nix {};
  ida-structor = super.callPackage ./ida-structor.nix {};
  ida-lifter = super.callPackage ./ida-lifter.nix {};
  ida-hrtng = super.callPackage ./ida-hrtng.nix {
    inherit (_self) ida-sdk-source;
  };
  ida-bitopt = super.callPackage ./ida-bitopt.nix {};
  ida-d810 = super.callPackage ./ida-d810.nix {};
  ida-pro = super.callPackage ./ida-pro.nix {
    plugins = with _self; [ida-nexus ida-mcp ida-codemode bindiff-ida binsync-ida ida-theme-explorer ida-wakatime ida-guides ida-sigmaker ida-structor ida-lifter ida-hrtng ida-bitopt ida-d810];
    extraPythonPackages = ps:
      (_self.binsync-ida.passthru.pythonPackages ps)
      ++ (_self.headless-ida.passthru.pythonPackages ps)
      ++ (_self.ida-nexus.passthru.pythonPackages ps)
      ++ (_self.ida-codemode.passthru.pythonPackages ps)
      ++ (_self.ida-d810.passthru.pythonPackages ps);
  };
  ida-mcp-rs = super.callPackage ./ida-mcp-rs.nix {
    inherit (_self) ida-pro;
  };
}
