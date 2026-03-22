{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      binary-ninja = super.callPackage ../../pkgs/binary-ninja.nix {};
    })
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy.nix {};
    })
    (_self: super: {
      msty = super.callPackage ../../pkgs/msty.nix {};
    })
    # Just use the unstable version, which is almost always up-to-date and then we don't have to care about manually updating.
    # (_self: super: {
    #   claude-code = super.callPackage ../../pkgs/claude-code/default.nix {};
    # })
    (_self: super: {
      feishin = super.callPackage ../../pkgs/feishin.nix {};
    })
    (_self: super: {
      solidtime-desktop = super.callPackage ../../pkgs/solidtime.nix {};
    })
    (_self: super: {
      zessionizer = super.callPackage ../../pkgs/zessionizer.nix {inherit (super) fenix;};
    })
    (_self: super: {
      antigravity = super.callPackage ../../pkgs/antigravity.nix {};
    })
    (_self: super: {
      vmprotect = super.callPackage ../../pkgs/vmprotect.nix {};
    })
    (_self: super: {
      ghidra-cli = super.callPackage ../../pkgs/ghidra-cli.nix {};
    })
    (_self: super: {
      audiomuse-ai = super.callPackage ../../pkgs/audiomuse-ai.nix {};
    })
    (_self: super: {
      audiomuse-ai-nv-plugin = super.callPackage ../../pkgs/audiomuse-ai-nv-plugin.nix {};
    })
    (_self: super: {
      soulsync = super.callPackage ../../pkgs/soulsync.nix {};
    })
    (_self: super: {
      pi-coding-agent = super.callPackage ../../pkgs/pi-mono {};
    })
    (_self: super: {
      paperclip = super.callPackage ../../pkgs/paperclip.nix {};
    })
    (_self: super: {
      qmd = super.callPackage ../../pkgs/qmd.nix {};
    })
    # (_self: super: {
    #   lobe-chat = super.callPackage ../../pkgs/lobe-chat.nix {};
    # })
    (_self: super: {
      rtk = super.callPackage ../../pkgs/rtk.nix {};
    })
    (_self: super: {
      hermes-agent = super.callPackage ../../pkgs/hermes-agent.nix {};
    })
    (_self: super: {
      pi-session-cli = super.callPackage ../../pkgs/pi-session-manager.nix {};
    })
    (import ../../pkgs/ida-pro)
  ];
}
