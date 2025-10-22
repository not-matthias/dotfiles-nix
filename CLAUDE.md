# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## IMPORTANT NOTES

- **Primary development machine**: Always build for framework (`sudo nixos-rebuild switch --flake .#framework`) when in doubt
- Building for desktop can cause issues on this machine
- Pre-commit hooks run automatically on commit (alejandra formatting, shellcheck, deadnix cleanup)

## Development Commands

### System Building and Management

#### Build Commands
```bash
# Full rebuild and switch (evaluate → build → activate)
sudo nixos-rebuild switch --flake .#framework

# Build without activating (useful for testing)
sudo nixos-rebuild build --flake .#framework

# Set as next boot target (activate on next reboot)
sudo nixos-rebuild boot --flake .#framework
```

#### Quick Build Scripts (via devenv)
Available in devenv shell (after `nix develop`):
```bash
bf    # Build framework: nh os switch -H framework . -- --accept-flake-config
bd    # Build desktop: nh os switch -H desktop . -- --accept-flake-config
br    # Build raspi: nh os switch -H raspi . -- --accept-flake-config
```

#### Debugging Builds
```bash
# Show full evaluation trace for errors
sudo nixos-rebuild switch --flake .#framework --show-trace

# Force cache invalidation (fixes "cached failure" errors)
sudo nixos-rebuild switch --flake .#framework --option eval-cache false

# Update all flake inputs before rebuilding
nix flake update
```

#### Cleanup and Optimization
```bash
# Remove unreferenced store entries
nix-collect-garbage -d                 # User packages
sudo nix-collect-garbage -d            # System derivations

# Optimize Nix store (deduplicate and compact)
nix store optimise                     # Modern command
nix-store --optimize                   # Legacy command
```

### Development Environment
```bash
# Enter development shell with pre-commit hooks enabled
nix develop

# Or with direnv (if configured)
direnv allow
```

Pre-commit hooks automatically run on commit:
- **alejandra**: Nix code formatting
- **shellcheck**: Shell script linting
- **deadnix**: Finds and removes unused Nix code (with --edit enabled)

### Temporary Package Installation
```bash
# Install packages temporarily for testing/development
nix-shell -p <package>              # Single package
nix-shell -p lapce                  # Example: Lapce editor
nix-shell -p traceroute gping       # Multiple packages
nix-shell -p networkmanagerapplet   # Network manager applet
nix-shell -p wl-clipboard           # Wayland clipboard tools

# Alternative using nix run (for applications)
nix run nixpkgs#<package>           # Run package directly
nix run github:<user>/<repo>        # Run from GitHub flake
```

### Custom Packages (pkgs/)
Custom Nix packages are defined in `pkgs/` directory. These are included via overlay in the nixosBox factory.

```bash
# Build a custom package
nix build -f pkgs/handy.nix

# Run a custom package directly
nix run -f pkgs/handy.nix

# Test custom package build
nix-build --impure -f pkgs/<package>.nix
```

See `pkgs/README.md` for details on developing custom packages.

### Secrets Management (agenix)
```bash
# Edit existing secret
agenix -e <secret-name>.age

# Create new secret from stdin
cat file.txt | agenix -e file.age
```

## Repository Architecture

### Flake Structure
- **Inputs**: NixOS 25.05 stable, nixpkgs-unstable, home-manager, nixvim, agenix, zen-browser, fenix, arion, nixos-hardware, elephant, walker, niri, stylix, quickshell, and others
- **User**: "not-matthias" (hardcoded in flake.nix outputs)
- **Hosts**: Three active configs (desktop, framework, raspi) defined via `nixosBox` factory in `hosts/default.nix`

### Directory Organization
```
hosts/                  # Host-specific configurations
├── configuration.nix   # Common system configuration
├── default.nix        # Host factory function with nixosBox
├── home.nix           # Common home-manager configuration  
├── desktop/           # Desktop machine config
├── framework/         # Framework laptop config
└── raspi/             # Raspberry Pi config

modules/
├── home/              # Home Manager modules
│   ├── programs/      # User application configurations
│   └── services/      # User services
├── overlays/          # Nix package overlays
└── system/            # NixOS system modules
    ├── desktop/       # Desktop environment configs
    ├── hardware/      # Hardware-specific modules  
    ├── programs/      # System programs
    ├── services/      # System services
    └── virtualization/ # VM and container configs

pkgs/                  # Custom package definitions
secrets/               # Age-encrypted secrets
```

### The nixosBox Factory Pattern (hosts/default.nix:18-102)
The `nixosBox` function is the core abstraction that creates consistent NixOS configurations:

**Signature**: `nixosBox arch base name domain` where:
- `arch`: System architecture (x86_64-linux or aarch64-linux)
- `base`: Which nixpkgs set to use (stable for all currently)
- `name`: Directory name in hosts/ (desktop, framework, raspi)
- `domain`: FQDN for the system

**What it does**:
1. Creates isolated pkgs sets for stable, unstable, and NUR
2. Applies overlays (fenix for Rust, Google Fonts)
3. Imports common modules (configuration.nix, home.nix)
4. Integrates Home Manager with proper special arguments
5. Returns a NixOS system configuration

**How to add a new host**: Add entry in `hosts/default.nix:104-106`, create `hosts/<name>/default.nix` with modules, and ensure hardware-configuration.nix is present.

### Module Architecture
- **System modules** (`modules/system/`): Hardware, services, system programs
- **Home modules** (`modules/home/`): User-space applications and services  
- **Clean separation** between system and user configurations
- **Kebab-case preservation**: Keep attribute names like `ui-port`, `api-port` even if inconsistent with Nix conventions

## Key Technologies and Stack

### Desktop Environment
- **Primary**: Hyprland with Waybar status bar, Walker launcher
- **Alternatives**: Sway, GNOME (with extensions), Niri (scrollable-tiling compositor)
- **Wayland stack**: SwayLock, Swww wallpapers, Dunst notifications

#### Niri Documentation
- **Main README**: https://raw.githubusercontent.com/sodiboo/niri-flake/refs/heads/main/README.md
- **Configuration docs**: https://raw.githubusercontent.com/sodiboo/niri-flake/refs/heads/main/docs.md
- **Binary cache**: niri.cachix.org (configured in modules/system/desktop/niri/default.nix)
- **Package options**: niri-stable, niri-unstable via flake overlay

#### Niri Commands
```bash
# List current outputs and their modes
niri msg outputs

# Set output mode manually (runtime only, not persistent)
niri msg output <output-name> mode <width>x<height>@<refresh>
niri msg output DP-1 mode 1920x1080@74.973

# Other useful commands
niri msg workspaces              # List workspaces
niri msg windows                 # List windows
```

### Development Tools
- **Editors**: Nixvim (primary), Helix, VSCode, Zed, IntelliJ IDEA
- **Shell**: Fish with custom prompt and abbreviations
- **Terminal**: Alacritty, Kitty with Zellij/Tmux multiplexing
- **CLI tools**: ripgrep, fd, eza, bat, delta, zoxide (use `j` alias in fish)

### Self-Hosted Services (Desktop Host)
Services follow consistent patterns in `modules/system/services/`:
- **Media**: Jellyfin, Navidrome, Audiobookshelf, Maloja
- **Productivity**: Paperless, N8N, Memos, Tandoor, Firefly III
- **Development**: Gitea, Ollama (AI), Kokoro TTS
- **Monitoring**: Netdata, Scrutiny, Change Detection
- **Infrastructure**: Caddy reverse proxy, AdGuard Home
- **Port mappings**: Documented in `PORTS.md`

### Hardware Support Modules
- **GPU**: NVIDIA with CUDA support (`hardware.nvidia.enable`)
- **Storage**: ZFS with LUKS encryption (`hardware.zfs.enable`)
- **Audio**: PipeWire/PulseAudio
- **Power**: Custom power management with device-specific rules
- **Input devices**: Specialized Logitech device support

## Common Patterns and Conventions

### Service Configuration Pattern
1. Module definition in `modules/system/services/<service>.nix`
2. Host-specific enablement in `hosts/<hostname>/default.nix`
3. Port allocation documented in `PORTS.md`
4. Consistent option structure with enable flags

### Hardware Abstraction
Hardware modules provide clean boolean flags:
```nix
hardware.nvidia.enable = true;
hardware.zfs.enable = true;  
hardware.ssd.enable = true;
```

### Secrets Integration
- Uses agenix with SSH keys for encryption
- Identity paths configured per host in `secrets/secrets.nix`
- Secrets mounted at runtime in `/run/agenix/`

### Package Management
- **Stable**: Default from nixpkgs 25.05
- **Unstable**: Available via `pkgs-unstable` overlay
- **NUR**: Community packages via nurpkgs overlay
- **Custom**: Defined in `pkgs/` directory

## Development Workflow

### Making Changes
1. Identify the relevant module (system config, home config, custom service, etc.)
2. Make changes to the appropriate `.nix` file
3. Build locally with `sudo nixos-rebuild build --flake .#framework` to catch errors
4. Test the full configuration with `sudo nixos-rebuild switch --flake .#framework`
5. Pre-commit hooks run automatically (alejandra, shellcheck, deadnix)
6. Commit with conventional message format

### Documentation
- Keep an append-only log in `.claude/SCRATCHPAD.md` for significant changes
- Include date and brief description of what changed and why
- Useful for future reference and understanding decision history

### Commit Message Format
```bash
# Feature or significant change
git commit -m "feat: description"

# Bug fix
git commit -m "fix: description"

# Maintenance, refactoring, or documentation
git commit -m "chore: description"
```

## Troubleshooting
- **Cached failures**: Use `--option eval-cache false`
- **Command-not-found**: Update system channels with sudo
- **Devenv issues**: Remove `~/.cachix/nix` directory
- **Architecture**: Repository supports both x86_64-linux and aarch64-linux
