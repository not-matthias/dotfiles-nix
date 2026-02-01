---
name: cmkr-build
description: Guide for setting up and using cmkr.build, a modern CMake-based build system using TOML configuration. Use when creating new C++ projects, setting up CMake builds, converting from CMakeLists.txt, or when users mention cmkr, cmake.toml, or "CMake TOML".
---

<!-- Source: Original work based on https://cmkr.build/ documentation -->

# cmkr.build - Modern CMake with TOML

`cmkr` (pronounced "cmaker") is a modern build system that parses `cmake.toml` files and generates idiomatic `CMakeLists.txt`. It simplifies CMake by using TOML syntax while maintaining full CMake compatibility.

## Quick Start - New Project Setup

### 1. Bootstrap cmkr in Your Project

```bash
# Download the bootstrap script
curl https://raw.githubusercontent.com/build-cpp/cmkr/main/cmake/cmkr.cmake -o cmkr.cmake

# Run the bootstrap (downloads cmkr and generates initial files)
cmake -P cmkr.cmake
```

**What this does:**
- Downloads the cmkr executable to `build/_deps/cmkr-src/`
- Creates a minimal `cmake.toml` file if it doesn't exist
- Generates `CMakeLists.txt` from your `cmake.toml`

### 2. Configure Your Project in cmake.toml

```toml
[project]
name = "myproject"
version = "1.0.0"
description = "My awesome C++ project"
languages = ["CXX"]

[target.myapp]
type = "executable"
sources = ["src/main.cpp"]
```

### 3. Build Your Project

```bash
# Configure (cmkr auto-regenerates CMakeLists.txt if cmake.toml changed)
cmake -B build

# Build
cmake --build build

# Run
./build/myapp
```

**No extra steps!** After modifying `cmake.toml`, just run `cmake --build build` and cmkr automatically regenerates `CMakeLists.txt`.

## Understanding cmkr Architecture

### How It Works

```
cmake.toml → [cmkr parses] → CMakeLists.txt → [CMake processes] → Build files
```

1. **You edit** `cmake.toml` (clean, readable TOML syntax)
2. **cmkr generates** modern, idiomatic `CMakeLists.txt`
3. **CMake processes** the generated file normally
4. **Your build system** (Make, Ninja, Visual Studio) compiles

### File Commit Guide

**Commit these to version control:**
- ✅ `cmake.toml` - Your project configuration
- ✅ `cmkr.cmake` - Bootstrap script (enables CI builds)
- ✅ `CMakeLists.txt` - Generated (regenerates automatically)

## cmake.toml Reference

### Project Section [project]

```toml
[project]
name = "myproject"                    # Required: project name
version = "1.0.0"                     # Optional: project version
description = "Description here"      # Optional: project description
languages = ["CXX", "C"]              # Optional: enabled languages
cmake-before = """                   # Optional: CMake code before project()
message(STATUS "Before project")
"""
cmake-after = """                    # Optional: CMake code after project()
message(STATUS "After project")
"""
```

**Supported languages:** C, CXX (C++), CSharp, CUDA, OBJC, OBJCXX, Fortran, HIP, ISPC, Swift, ASM, ASM_MASM (MASM), ASM_NASM, ASM_MARMASM, ASM-ATT

### Target Section [target.<name>]

```toml
[target.mylib]
type = "static"                       # Required: executable, library, shared, static, interface, object, custom
sources = ["src/*.cpp"]               # Source files (supports globbing)
headers = ["include/*.hpp"]           # Header files (for documentation)
include-directories = ["include"]     # Public include paths
compile-definitions = ["MYLIB_EXPORT"] # Preprocessor defines
compile-features = ["cxx_std_20"]     # C++ standard version
compile-options = ["-Wall", "-Wextra"] # Compiler flags
link-libraries = ["otherlib"]         # Link dependencies
link-options = []                     # Linker flags
precompile-headers = ["pch.hpp"]      # Precompiled headers

[target.mylib.properties]
CXX_STANDARD = 17
CXX_STANDARD_REQUIRED = true
```

**Target Types:**
| Type | Purpose | Visibility Default |
|------|---------|-------------------|
| `executable` | Program you run (.exe) | PRIVATE |
| `static` | Static library (.lib, .a) | PUBLIC |
| `shared` | Dynamic library (.dll, .so, .dylib) | PUBLIC |
| `library` | Let CMake decide static/shared | PUBLIC |
| `interface` | Header-only library | INTERFACE |
| `object` | Object files collection | PUBLIC |

**Visibility Controls:**
- Public properties: `include-directories`, `compile-definitions`, `link-libraries`
- Private properties: Prefix with `private-` (e.g., `private-compile-options`)
- Interface-only: Use on `interface` targets

### Conditions [conditions]

```toml
[conditions]
# Predefined (override if needed):
windows = "WIN32"
macos = "CMAKE_SYSTEM_NAME MATCHES \"Darwin\""
linux = "CMAKE_SYSTEM_NAME MATCHES \"Linux\""
unix = "UNIX"
msvc = "MSVC"
clang = "CMAKE_CXX_COMPILER_ID MATCHES \"Clang\""
gcc = "CMAKE_CXX_COMPILER_ID STREQUAL \"GNU\""
x64 = "CMAKE_SIZEOF_VOID_P EQUAL 8"
root = "CMKR_ROOT_PROJECT"

# Custom conditions:
build-tests = "MYPROJECT_BUILD_TESTS"
ptr64 = "CMAKE_SIZEOF_VOID_P EQUAL 8"
```

**Using conditions:**
```toml
[target.myapp]
type = "executable"
sources = ["src/main.cpp"]
windows.sources = ["src/win32_specific.cpp"]
linux.compile-options = ["-fPIC"]
```

### Options [options]

```toml
[options]
MYPROJECT_BUILD_TESTS = false
MYPROJECT_BUILD_EXAMPLES = { value = true, help = "Build example programs" }
MYPROJECT_ENABLE_FEATURE = "root"     # Only true if this is root project
```

**Usage:**
```bash
cmake -B build -DMYPROJECT_BUILD_TESTS=ON
```

Each option creates a condition with the same name (lowercase, dashes).

### Variables [variables]

```toml
[variables]
MY_CUSTOM_VAR = "value"
MY_BOOL_VAR = true
```

Emits: `set(MY_CUSTOM_VAR "value")`

### Dependencies

#### vcpkg [vcpkg]

```toml
[vcpkg]
version = "2024.11.16"                # vcpkg version (auto-generates URL)
packages = ["fmt", "zlib", "boost"]   # Packages to install

# Package with features:
# packages = ["imgui[docking-experimental,freetype,sdl2-binding]"]

# Disable default features:
# packages = ["cpp-httplib[core,openssl]"]

overlay-ports = ["my-ports"]          # Custom ports directory
overlay-triplets = ["my-triplets"]    # Custom triplets directory
overlay = "vcpkg-overlay"             # Both in one directory
```

#### FetchContent [fetch-content.<name>]

```toml
[fetch-content.fmt]
git = "https://github.com/fmtlib/fmt"
tag = "10.2.1"
shallow = true                        # --depth 1

[fetch-content.somelib]
url = "https://example.com/lib.zip"
sha256 = "abc123..."
```

#### Find Package [find-package.<name>]

```toml
[find-package.Boost]
required = true
version = "1.82"
components = ["filesystem", "system"]

[find-package.OpenSSL]
required = false
config = true
```

### Subdirectories [subdir.<name>]

```toml
[subdir.thirdparty]
condition = "root"                    # Only add if this is root project
```

### Templates [template.<name>]

```toml
[template.example]
condition = "build-examples"
type = "executable"
link-libraries = ["mylib::mylib"]
add-function = ""                     # Custom add function (e.g., pybind11_add_module)
add-arguments = []                    # Arguments to add-function
pass-sources = false                  # Pass sources to add-function

[target.example1]
type = "example"
sources = ["examples/example1.cpp"]
```

## Common Project Examples

### Simple Executable

```toml
[project]
name = "hello"
version = "1.0.0"

[target.hello]
type = "executable"
sources = ["src/main.cpp"]
```

### Library with Examples

```toml
[project]
name = "mylib"
version = "2.0.0"

[options]
MYLIB_BUILD_EXAMPLES = { value = true, help = "Build examples" }

[target.mylib]
type = "static"
sources = ["src/mylib.cpp"]
headers = ["include/mylib.hpp"]
include-directories = ["include"]

[template.example]
condition = "mylib-build-examples"
type = "executable"
link-libraries = ["mylib"]

[target.example_basic]
type = "example"
sources = ["examples/basic.cpp"]
```

### Using vcpkg Dependencies

```toml
[project]
name = "app-with-deps"

[vcpkg]
packages = ["fmt", "spdlog", "nlohmann-json"]

[target.app]
type = "executable"
sources = ["src/main.cpp"]
link-libraries = ["fmt::fmt", "spdlog::spdlog", "nlohmann_json::nlohmann_json"]
```

### Platform-Specific Code

```toml
[project]
name = "cross-platform"

[target.app]
type = "executable"
sources = ["src/main.cpp", "src/common.cpp"]

# Windows-specific
windows.sources = ["src/win32.cpp"]
windows.link-libraries = ["kernel32"]

# Linux-specific
linux.sources = ["src/linux.cpp"]
linux.compile-options = ["-fPIC"]
linux.link-libraries = ["pthread"]

# macOS-specific
macos.sources = ["src/macos.cpp"]
macos.compile-options = ["-mmacosx-version-min=10.14"]
```

### Header-Only Library

```toml
[project]
name = "header-lib"

[target.header-lib]
type = "interface"
headers = ["include/header-lib/*.hpp"]
include-directories = ["include"]
```

### Multiple Targets

```toml
[project]
name = "multi-target"

[target.lib1]
type = "static"
sources = ["lib1/*.cpp"]
include-directories = ["lib1/include"]

[target.lib2]
type = "static"
sources = ["lib2/*.cpp"]
include-directories = ["lib2/include"]
link-libraries = ["lib1"]

[target.app]
type = "executable"
sources = ["app/main.cpp"]
link-libraries = ["lib2"]
```

## CLI Commands

If you install cmkr to your PATH:

```bash
cmkr init [type]          # Create new project (executable|library|shared|static|interface)
cmkr gen                  # Regenerate CMakeLists.txt manually
cmkr build [args]         # Configure and build
cmkr install              # Run cmake --install
cmkr clean                # Clean build directory
cmkr help                 # Show help
cmkr version              # Show version
```

**Without cmkr in PATH** (using CMake only):
```bash
# Regenerate (if cmake.toml changed)
cmake -B build

# Force regeneration
cmake -B build --fresh
```

## CMake Integration

### In CI/CD

```yaml
# GitHub Actions example
steps:
  - uses: actions/checkout@v4
  - name: Configure
    run: cmake -B build
  - name: Build
    run: cmake --build build
  - name: Test
    run: ctest --test-dir build
```

**No special setup needed!** The `cmkr.cmake` bootstrap handles everything. In CI, cmkr downloads itself automatically on first configure.

### With IDEs

**VS Code:**
- Install CMake Tools extension
- cmkr automatically regenerates `CMakeLists.txt` when you save `cmake.toml`
- Works seamlessly with IntelliSense and debugging

**CLion:**
- Open project with `CMakeLists.txt`
- Edit `cmake.toml`, save
- CLion auto-detects changes and reloads

**Visual Studio:**
- Open folder with `CMakeLists.txt`
- cmkr manages regeneration automatically

## Build Types

```bash
# Debug (default)
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Release
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# RelWithDebInfo (optimized with debug symbols)
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo

# MinSizeRel (minimum size)
cmake -B build -DCMAKE_BUILD_TYPE=MinSizeRel
```

## Troubleshooting

### Issue: CMakeLists.txt not regenerating

**Solution:**
```bash
# Force regeneration
cmake -B build --fresh

# Or manually trigger
cmake -B build
```

### Issue: vcpkg packages not found

**Solution:**
```bash
# Delete build directory to reset vcpkg
cmake -E rm -rf build
cmake -B build
```

### Issue: Link errors with libraries

**Solution:**
- Ensure `link-libraries` uses target names (e.g., `fmt::fmt` not just `fmt`)
- Check visibility: Public for libraries, Private for executables
- Verify Find Package or Fetch Content is configured

### Issue: cmkr bootstrap fails

**Solution:**
```bash
# Manual download
curl -L https://github.com/build-cpp/cmkr/releases/latest/download/cmkr -o cmkr
chmod +x cmkr
./cmkr gen
```

## Best Practices

1. **Start simple:** Begin with minimal `cmake.toml`, add complexity incrementally
2. **Use templates:** For repeated target patterns (examples, tests)
3. **Leverage conditions:** Keep platform-specific code organized
4. **Commit bootstrap:** Include `cmkr.cmake` in version control for CI
5. **Prefer vcpkg:** For dependencies, use vcpkg when available
6. **Check before commit:** `cmake.toml` and `CMakeLists.txt` should both be committed

## Migration from CMakeLists.txt

1. Create `cmake.toml` with equivalent structure
2. Run `cmake -P cmkr.cmake` to generate
3. Compare generated `CMakeLists.txt` with original
4. Adjust `cmake.toml` until output matches desired CMake
5. Remove manual `CMakeLists.txt` edits (they get overwritten)

## Resources

- **Documentation:** https://cmkr.build/
- **GitHub:** https://github.com/build-cpp/cmkr
- **Examples:** https://cmkr.build/examples/
- **Template:** https://github.com/build-cpp/cmkr_for_beginners
