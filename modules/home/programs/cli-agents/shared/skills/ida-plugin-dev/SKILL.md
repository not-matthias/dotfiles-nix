---
name: ida-plugin-dev
description: IDA Pro plugin development - SDK setup, CMake build patterns, Python plugin structure, Nix packaging, and common gotchas for IDA 9.x.
license: MIT
---

# IDA Pro Plugin Development

Patterns for developing IDA Pro plugins (C++ and Python), building against the IDA SDK, and packaging for NixOS.

## When to Use This Skill

- Creating a new IDA plugin (C++ or Python)
- Setting up CMake build against IDA SDK
- Packaging an IDA plugin in Nix
- Debugging IDA runtime dependency issues on NixOS

## Python Plugin Structure

### Entry point

```python
def PLUGIN_ENTRY(*args, **kwargs):
    """IDA calls this to load the plugin."""
    return create_plugin(*args, **kwargs)

# Handle non-IDA environments gracefully
try:
    import idaapi
    HAS_IDA = True
except ImportError:
    HAS_IDA = False
    create_plugin()
```

### Plugin metadata (`ida-plugin.json`)

```json
{
  "IDAMetadataDescriptorVersion": 1,
  "plugin": {
    "name": "My Plugin",
    "entryPoint": "src/my_plugin/plugin.py",
    "categories": ["api-scripting-and-automation"],
    "description": "Does X",
    "idaVersions": ">=8.3"
  }
}
```

Requirements: Python 3.11+, IDA Pro 8.3+ (IDA Free not supported).

### `pyproject.toml`

```toml
[build-system]
requires = ["setuptools>=61.2"]
build-backend = "setuptools.build_meta"

[project]
name = "my-ida-plugin"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = ["idapro>=0.0.7"]

[project.scripts]
my-plugin = "my_plugin.server:main"
```

## C++ Plugin Build (CMake)

### `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.15)
project(my_plugin CXX)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error -Wno-format-security")

set(IDA_SDK_DIR "" CACHE PATH "Path to IDA SDK")
if(NOT IDA_SDK_DIR OR NOT EXISTS "${IDA_SDK_DIR}")
  message(FATAL_ERROR "IDA_SDK_DIR not set")
endif()

list(APPEND CMAKE_MODULE_PATH "${IDA_SDK_DIR}/cmake")
include(ida-sdk)

add_ida_plugin(my_plugin
  src/plugin.cpp
)
```

### Nix derivation for C++ plugin

```nix
{stdenv, cmake, ninja, clang, ida-sdk-source}: stdenv.mkDerivation {
  pname = "ida-my-plugin";
  version = "1.0.0";

  src = fetchFromGitHub { ... };

  nativeBuildInputs = [cmake ninja clang];

  # Critical: IDA SDK is read-only in Nix store — must copy to $TMPDIR
  preConfigure = ''
    export TMP_SDK=$TMPDIR/ida-sdk
    cp -r ${ida-sdk-source} $TMP_SDK
    chmod -R u+w $TMP_SDK
  '';

  cmakeFlags = [
    "-DIDA_SDK_DIR=$TMP_SDK"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_CXX_FLAGS=-Wno-error -Wno-format-security"
  ];

  installPhase = ''
    mkdir -p $out/plugins
    cp *.so $out/plugins/
  '';
}
```

**Gotcha:** The Nix store is read-only. IDA's CMake scripts write into the SDK directory during configuration. Always copy to `$TMPDIR` and `chmod -R u+w` before configuring.

## IDA SDK Source Package

```nix
# pkgs/ida-pro/ida-sdk-source.nix
{stdenv, fetchFromGitHub}: stdenv.mkDerivation rec {
  pname = "ida-sdk-source";
  version = "9.3";

  src = fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-sdk";
    rev = "v${version}";
    hash = "sha256-...";
    fetchSubmodules = true;  # Required
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/
    cd $out
    ln -s src/include include
    ln -s src/lib lib
    ln -s src/cmake cmake
  '';
}
```

SDK structure: `src/include/` (headers like `ida.hpp`, `idp.hpp`), `src/lib/` (link libs), `src/cmake/` (CMake modules).

## Python Plugin (.py) Nix Package

```nix
{stdenv, fetchurl}: stdenv.mkDerivation {
  pname = "ida-my-script";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/.../releases/download/.../plugin.py";
    sha256 = "...";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/plugins
    cp ${src} $out/plugins/plugin.py
  '';
}
```

## NixOS Runtime Dependencies

IDA Pro 9.x requires Qt6. Common missing libraries on NixOS:

```nix
runtimeDependencies = with pkgs; [
  libGL libxkbcommon libxcb
  qt6.qtbase qt6.qtwayland
  glib gtk3 libdrm
  libkrb5 openssl.out curl.out
  xorg.libX11
];
```

If IDA fails to start:
```bash
# Quick test — add libraries one by one
nix-shell -p libGL libxkbcommon libxcb qt6.qtbase glib xorg.libX11 \
  --run "ida64"
```

## Testing Plugins

```bash
# Python plugin via MCP Inspector
npx -y @modelcontextprotocol/inspector
# Opens http://localhost:5173

# HTTP (if plugin exposes RPC on :13337)
curl -X POST http://localhost:13337/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"call_tool","params":{"name":"my_tool","params":{}}}'

# C++ plugin: verify .so was created
cmake --build . --verbose
ls -la *.so
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `IDA SDK dir is read-only` | Nix store immutable | Copy SDK to `$TMPDIR`, `chmod -R u+w` |
| `libGL.so.1: not found` | Missing OpenGL | Add `libGL` to runtimeDependencies |
| `idaapi` import fails outside IDA | No IDA Python env | Guard with `try: import idaapi` |
| Plugin `.so` not found after build | CMake target name mismatch | Check `add_ida_plugin()` target name |
| IDA Python version mismatch | Wrong Python in PATH | Use `pythonForIDA` with rpyc |

## References

- SDK: https://github.com/HexRaysSA/ida-sdk (v9.3 for IDA 9.x)
- Python template: https://github.com/mrexodia/ida-pro-mcp
- Local packages: `pkgs/ida-pro/` in this dotfiles repo
