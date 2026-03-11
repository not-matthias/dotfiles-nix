_self: super: {
  ida-sigmaker = super.callPackage ./ida-sigmaker.nix {};
  ida-guides = super.callPackage ./ida-guides.nix {};
  ida-wakatime = super.callPackage ./ida-wakatime.nix {};
  ida-pro-mcp = super.callPackage ./ida-pro-mcp.nix {};
  bindiff-ida = super.callPackage ./bindiff.nix {};
  binsync-ida = super.callPackage ./binsync.nix {};
  ida-theme-explorer = super.callPackage ./ida-theme-explorer.nix {};
  headless-ida = super.callPackage ./headless-ida.nix {};
  ida-sdk-source = super.callPackage ./ida-sdk-source.nix {};
  ida-structor = super.callPackage ./ida-structor.nix {};
  ida-lifter = super.callPackage ./ida-lifter.nix {};
  ida-pro = super.callPackage ./ida-pro.nix {
    plugins = with _self; [ida-pro-mcp bindiff-ida binsync-ida ida-theme-explorer ida-wakatime ida-guides ida-sigmaker ida-structor ida-lifter];
    extraPythonPackages = ps:
      (_self.binsync-ida.passthru.pythonPackages ps)
      ++ (_self.headless-ida.passthru.pythonPackages ps);
  };
  ida-mcp-rs = super.callPackage ./ida-mcp-rs.nix {
    inherit (_self) ida-pro;
  };
}
