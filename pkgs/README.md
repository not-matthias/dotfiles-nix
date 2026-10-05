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

## Tern

- 2026-10-05: Include WebKitGTK 4.1 and GLib's TLS modules for embedded HTTPS pages.
- Launch the package's `bin/tern` wrapper; the binary in `libexec/tern` does not set up TLS modules.
