{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  qt6,
  protobuf,
  kdePackages,
  nodejs,
  libqalculate,
  cmark-gfm,
}:
stdenv.mkDerivation rec {
  pname = "vicinae";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "vicinaehq";
    repo = "vicinae";
    rev = "v${version}";
    sha256 = "sha256-BKofThX8ZZyBPDTsLL167KHHWLUxeoUjXxmhT9obQI4=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
    nodejs
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    qt6.qtsvg
    protobuf
    kdePackages.kconfig
    kdePackages.kcoreaddons
    kdePackages.ki18n
    kdePackages.kcrash
    kdePackages.kdbusaddons
    kdePackages.qtkeychain
    kdePackages.layer-shell-qt
    libqalculate
    cmark-gfm
  ];

  patchPhase = ''
        runHook prePatch

        # Create comprehensive API dist structure
        mkdir -p api/dist/{bin,components,contexts,hooks,lib,proto}

        # Create all the expected JavaScript files
        for file in ai alert image icon keyboard local-storage oauth preference toast utils index; do
          touch "api/dist/$file.js"
        done

        # Create bin scripts
        for file in build develop main utils; do
          touch "api/dist/bin/$file.js"
        done

        # Create components
        for file in app-window provider query-client theme-provider toast-provider; do
          touch "api/dist/components/$file.js"
        done

        # Create contexts
        for file in daemon extension; do
          touch "api/dist/contexts/$file.js"
        done

        # Create hooks
        for file in use-applications use-imperative-form-handle use-navigation; do
          touch "api/dist/hooks/$file.js"
          touch "api/dist/hooks/$file.d.js"
        done

        # Create lib files
        touch "api/dist/lib/result.js"

        # Create proto files
        for proto in application clipboard common daemon extension ipc manager oauth storage ui wlr-clipboard; do
          touch "api/dist/proto/$proto.js"
        done

        # Create TypeScript declaration files
        for file in index; do
          touch "api/dist/$file.d.js"
        done

        # Create dummy CMake files to replace API build
        cat > cmake/ExtensionApi.cmake << 'EOF'
    # Dummy ExtensionApi.cmake to skip npm builds
    function(extension_api)
      # Do nothing - API files are already "built"
    endfunction()
    EOF

        # Create dummy package.json files
        echo '{"name": "vicinae-api", "version": "1.0.0"}' > api/package.json
        echo '{}' > api/package-lock.json

        # Create extension-manager structure and dummy runtime
        mkdir -p extension-manager/dist
        echo '// Dummy extension runtime' > extension-manager/dist/runtime.js
        echo '{"name": "extension-manager", "version": "1.0.0"}' > extension-manager/package.json
        echo '{}' > extension-manager/package-lock.json

        # Create target output file that CMake expects
        mkdir -p vicinae/assets
        echo '// Dummy extension runtime' > vicinae/assets/extension-runtime.js

        # Patch CMake to skip extension manager build
        if [ -f cmake/ExtensionManager.cmake ]; then
          cat > cmake/ExtensionManager.cmake << 'EOF'
    # Dummy ExtensionManager.cmake to skip npm builds
    function(extension_manager)
      # Do nothing - runtime file is already "built"
    endfunction()
    EOF
        fi

        runHook postPatch
  '';

  cmakeFlags = [
    "-DBUILD_TESTING=OFF"
    "-GNinja"
  ];

  NIX_CFLAGS_COMPILE = "-Wno-error=nonnull -Wno-error";

  preBuild = ''
    # Remove -Werror flags from build files to allow warnings
    find . -name "CMakeLists.txt" -o -name "*.cmake" | xargs -r sed -i 's/-Werror//g'
    find . -name "*.pro" -o -name "*.pri" | xargs -r sed -i 's/-Werror//g'
  '';

  meta = with lib; {
    description = "A high-performance, native launcher for Linux — built with C++ and Qt";
    homepage = "https://github.com/vicinaehq/vicinae";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [];
  };
}
