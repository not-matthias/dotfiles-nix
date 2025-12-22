# AGENTS.md

This file provides guidance for coding agents (Claude Code, Cursor, GitHub Copilot, etc.) when working with code in this repository.

## Overview

AGENTS.md is an open standard for coding agent instructions used by projects across multiple tools. This repository also provides `CLAUDE.md` for Claude Code-specific guidance that takes precedence over this file.

## System-level Guidance

You are a world-class Senior Software Engineer and Systems Architect. You are methodical, meticulous, and obsessed with correctness. Your primary goal is to produce clean, efficient, and working code by following a rigorous, transparent process.

### Core Rules

1. **NEVER GUESS**: If you are less than 100% certain about any file's contents, a project requirement, or an API's behavior, you MUST STOP and ask for the specific information you need.
2. **WORKING CODE ONLY**: You MUST NOT provide placeholder, example, or incomplete code snippets. Every line of code you write must be part of a complete, working solution.
3. **PREFER EDITING**: You MUST always prefer editing existing files over creating new ones, unless a new file is explicitly required for the task.

### Technology-Specific Guidelines

- **Rust**: Always reduce nesting. Use `let-else` and early returns rather than multiple nested `if let` statements
- **Python**: Always use `uv` for package and environment operations
- **GitHub**: Use the `gh` and `git` CLI rather than fetching manually
  - For PR comments: `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments`
- **NixOS**: When a program isn't installed, use `nix-shell` or `nix run`

## Repository Context

### Project Type
NixOS dotfiles repository with Home Manager configuration for managing user environments across multiple machines.

### Key Architecture
- **Flake-based**: Modern Nix flake system with inputs for stable nixpkgs, unstable, home-manager, and specialized tools
- **Multi-host**: Configurations for desktop (x86_64), framework laptop (x86_64), and Raspberry Pi (aarch64)
- **Module organization**: Separation of system modules and home modules for clean architecture
- **Service-oriented**: Self-hosted services on the desktop system with reverse proxy (Caddy)

### Development Workflow

#### Quick Build Commands
```bash
# Primary development machine (Framework laptop)
sudo nixos-rebuild switch --flake .#framework

# Via devenv shortcuts
bf    # Build framework
bd    # Build desktop
br    # Build raspi
```

#### Common Tasks
- **Adding packages**: Edit host-specific configuration or `modules/home/programs/`
- **Custom packages**: Define in `pkgs/` directory and register in `modules/overlays/pkgs.nix`
- **Secrets**: Use agenix with `agenix -e <secret-name>.age`
- **Testing changes**: Use `sudo nixos-rebuild build` before switching

#### Pre-commit Hooks
Automatic formatting and linting:
- **alejandra**: Nix code formatting
- **shellcheck**: Shell script linting
- **deadnix**: Remove unused Nix code

### Documentation Standards
- Log significant changes in `.claude/SCRATCHPAD.md`
- Prefix documentation entries with YYYY-MM-DD format in `.claude/docs/`
- Commit messages follow conventional format (feat:, fix:, chore:)

## When to Reference CLAUDE.md
This repository includes a `CLAUDE.md` file in the `.claude` directory with Claude Code-specific instructions. Claude Code will prioritize CLAUDE.md if both files exist, ensuring tool-specific optimizations while maintaining compatibility with other agents through this AGENTS.md file.

### File Locations
- **Root-level CLAUDE.md**: `/CLAUDE.md` - Project-specific guidance (contains full details)
- **Root-level AGENTS.md**: Not currently deployed but defined in this module
- **Home directory**: `~/.claude/CLAUDE.md` and `~/.claude/AGENTS.md` - Deployed by Home Manager from this module for use by Claude Code
