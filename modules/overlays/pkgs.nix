{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      binary-ninja = super.callPackage ../../pkgs/binary-ninja.nix {};
    })
    (_self: super: {
      aw-watcher-niri = super.callPackage ../../pkgs/aw-watcher-niri {};
    })
    (_self: super: {
      aw-watcher-media-player = super.callPackage ../../pkgs/aw-watcher-media-player.nix {};
    })
    (_self: super: {
      binja-wasm = super.callPackage ../../pkgs/binja-wasm.nix {};
    })
    (_self: super: {
      binja-headless = super.callPackage ../../pkgs/binja-headless.nix {};
    })
    (_self: super: {
      binja-codemode-mcp = super.callPackage ../../pkgs/binja-codemode-mcp.nix {};
    })
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy.nix {};
    })
    (_self: super: {
      msty = super.callPackage ../../pkgs/msty.nix {};
    })
    (_self: super: {
      lmstudio = super.callPackage ../../pkgs/lmstudio.nix {};
    })
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
      soulsync = super.callPackage ../../pkgs/soulsync.nix {};
    })
    (_self: super: {
      pi-coding-agent = super.callPackage ../../pkgs/pi-mono {};
    })
    (_self: super: {
      mcporter = super.callPackage ../../pkgs/mcporter.nix {};
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
      amp-cli = super.callPackage ../../pkgs/amp-cli.nix {};
    })
    (_self: super: {
      pi-session-cli = super.callPackage ../../pkgs/pi-session-manager.nix {};
    })
    (_self: super: {
      linear-cli = super.callPackage ../../pkgs/linear-cli.nix {};
    })
    (_self: super: {
      oh-my-pi = super.callPackage ../../pkgs/oh-my-pi.nix {};
    })
    (_self: super: {
      handy = super.callPackage ../../pkgs/handy.nix {};
    })
    (_self: super: {
      hushmic = super.callPackage ../../pkgs/hushmic.nix {};
    })
    (_self: super: {
      plannotator = super.callPackage ../../pkgs/plannotator.nix {};
    })
    (_self: super: {
      tldraw-offline = super.callPackage ../../pkgs/tldraw-offline.nix {};
    })
    (_self: super: {
      jcode = super.callPackage ../../pkgs/jcode.nix {};
    })
    (_self: super: {
      terminal-browser = super.callPackage ../../pkgs/terminal-browser.nix {};
    })
    (_self: super: {
      harbor = super.callPackage ../../pkgs/harbor.nix {};
    })
    (import ../../pkgs/ida-pro)
    (_self: super: {
      herdr-mirror-plugin = super.callPackage ../../pkgs/herdr-plugins/mirror.nix {};
    })
    (_self: super: {
      slk = super.callPackage ../../pkgs/slk.nix {};
    })
    (_self: super: {
      ffmpeg_9 = super.ffmpeg_8 or super.ffmpeg;
      wrapFirefox = super.callPackage ({ffmpeg_8 ? null, ...} @ args:
        super.callPackage (super.path + "/pkgs/applications/networking/browsers/firefox/wrapper.nix") (
          (builtins.removeAttrs args ["ffmpeg_8" "ffmpeg_9"])
          // (
            if ffmpeg_8 != null
            then {ffmpeg_7 = ffmpeg_8;}
            else {}
          )
        )) {};
    })
  ];
}
