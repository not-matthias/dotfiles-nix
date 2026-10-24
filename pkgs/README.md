# Custom Packages

## Development

Build with:
```
nix build -f foo.nix
```

Run with:
```
nix run -f foo.nix
```

## Binary packages

- 2026-10-22: Feishin, HushMic, and Navidrome use pinned upstream Linux release binaries. Navidrome retains the module's plugin selection and ffmpeg wrapper.
- ActivityWatch's Rust server and sync client use the official 0.14.1 bundle on x86_64 Linux, which includes the heartbeat-ID fix. Other architectures retain the patched source package.
- Handy and tldraw offline use AppImages. The AppImage extractor runs with shell error checking so a failed extraction cannot be registered as a successful, incomplete store output.
- Choosr and Steelix retain source builds because their selected packages include local fixes. Replacing them with unpatched binaries would drop those fixes. Feishin also retains source builds outside x86_64 Linux: the upstream ARM64 release includes an x86_64 native module.

## Tern

- 2026-10-05: Include WebKitGTK 4.1 and GLib's TLS modules for embedded HTTPS pages.
- Launch the package's `bin/tern` wrapper; the binary in `libexec/tern` does not set up TLS modules.

## Choosr

- 2026-10-08: Launch browsers through `gio launch` using their desktop files so quoted profile arguments such as `Profile 1` remain intact.
