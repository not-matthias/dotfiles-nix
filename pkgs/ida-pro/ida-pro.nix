{
  pkgs,
  lib,
  plugins ? [],
  extraPythonPackages ? (_ps: []),
  ...
}: let
  pythonForIDA = pkgs.python313.withPackages (
    ps: with ps; [rpyc] ++ extraPythonPackages ps
  );
in
  pkgs.stdenv.mkDerivation rec {
    pname = "ida-pro";
    version = "9.3";

    src = pkgs.requireFile {
      name = "ida-pro_93_x64linux.run";
      url = "https://my.hex-rays.com/";
      sha256 = "2ed43ae4bb84d74dcae6f0099210dfa8d61bfea4952f5f9a07a9aae16cb70f82";
    };

    license = pkgs.requireFile {
      name = "idapro.hexlic";
      url = "https://my.hex-rays.com/";
      sha256 = "b60465440c1f3c7dbc52e7771479b2ee06813a770f8892bbca61a46ab1388e1d";
    };

    patchedLibida = pkgs.requireFile {
      name = "libida.so";
      url = "https://my.hex-rays.com/";
      sha256 = "7eb70f6dc2d579cfaab7e0f006f577fed35364e640394dc86e75d4f1a357325f";
    };

    patchedLibida32 = pkgs.requireFile {
      name = "libida32.so";
      url = "https://my.hex-rays.com/";
      sha256 = "17985fa1a0d1bf404e19bde0a50ac712feabba0bea05f0aa8c06b8c010302596";
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
      autoPatchelfHook
      qt6.wrapQtAppsHook
    ];

    # We just get a runfile in $src, so no need to unpack it.
    dontUnpack = true;

    # Add everything to the RPATH, in case IDA decides to dlopen things.
    runtimeDependencies = with pkgs; [
      cairo
      dbus
      fontconfig
      freetype
      glib
      gtk3
      libdrm
      libGL
      libkrb5
      libsecret
      qt6.qtbase
      qt6.qtwayland
      libunwind
      libxkbcommon
      openssl.out
      stdenv.cc.cc
      libice
      libsm
      libx11
      libxau
      libxcb
      libxext
      libxi
      libxrender
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      zlib
      curl.out
      pythonForIDA
    ];
    buildInputs = runtimeDependencies;

    dontWrapQtApps = true;

    installPhase = ''
            runHook preInstall

            function print_debug_info() {
              if [ -f installbuilder_installer.log ]; then
                cat installbuilder_installer.log
              else
                echo "No debug information available."
              fi
            }

            trap print_debug_info EXIT

            mkdir -p $out/bin $out/lib $out/share/applications

            IDADIR="$out/opt"
            HOME="$out/opt"

            # Invoke the installer with the dynamic loader directly, avoiding the need
            # to copy it to fix permissions and patch the executable.
            $(cat $NIX_CC/nix-support/dynamic-linker) $src \
              --mode unattended --debuglevel 4 --prefix $IDADIR

            # Install the license file.
            cp $license $IDADIR/idapro.hexlic

            # Install patched libraries.
            cp $patchedLibida $IDADIR/libida.so
            cp $patchedLibida32 $IDADIR/libida32.so
            chmod +w $IDADIR/libida.so $IDADIR/libida32.so

            # Link the exported libraries to the output.
            for lib in $IDADIR/*.so $IDADIR/*.so.6; do
              [ -e "$lib" ] && ln -sf $lib $out/lib/$(basename $lib)
            done

            # Manually patch libraries that dlopen stuff.
            patchelf --add-needed libpython3.13.so $out/lib/libida.so
            patchelf --add-needed libcrypto.so $out/lib/libida.so
            patchelf --add-needed libsecret-1.so.0 $out/lib/libida.so

            # Some libraries come with the installer.
            addAutoPatchelfSearchPath $IDADIR

            # Install plugins.
            ${lib.concatMapStringsSep "\n" (plugin: ''
          echo "Installing plugin: ${plugin}"
          cp -r --no-clobber ${plugin}/* $IDADIR/ || true
        '')
        plugins}

            # Link the binaries to the output.
            for bb in ida; do
              wrapProgram $IDADIR/$bb \
                --prefix IDADIR : $IDADIR \
                --prefix QT_PLUGIN_PATH : $IDADIR/plugins/platforms \
                --prefix PYTHONPATH : $out/bin/idalib/python \
                --prefix PATH : ${pythonForIDA}/bin:$IDADIR \
                --prefix LD_LIBRARY_PATH : $out/lib \
                --set PYTHONHOME ${pythonForIDA} \
                --set _PYTHON_SYSCONFIGDATA_NAME _sysconfigdata__linux_x86_64-linux-gnu
              ln -s $IDADIR/$bb $out/bin/$bb
            done

            # Install desktop entry.
            if [ -d "$IDADIR/.local/share/applications" ]; then
              cp $IDADIR/.local/share/applications/*.desktop $out/share/applications/ 2>/dev/null || true
            fi

            # Create desktop entry if the installer didn't provide one.
            if [ ! -f $out/share/applications/ida-pro.desktop ]; then
              cat > $out/share/applications/ida-pro.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=IDA Pro
      Comment=Interactive Disassembler
      Exec=$out/bin/ida
      Icon=$IDADIR/appico64.png
      Terminal=false
      Categories=Development;Debugger;
      EOF
            fi

            runHook postInstall
    '';

    meta = with lib; {
      description = "The world's smartest and most feature-full disassembler";
      homepage = "https://hex-rays.com/ida-pro/";
      license = licenses.unfree;
      mainProgram = "ida";
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
