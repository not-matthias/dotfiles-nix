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

  hexraysCert = pkgs.fetchurl {
    url = "https://abda.nl/lumen/hexrays.crt";
    sha256 = "1h06akmrc79wrnq0ran0pnqf8vnni6qqb6dvg8kqr62d9nkaxgs8";
  };
in
  pkgs.stdenv.mkDerivation rec {
    pname = "ida-pro";
    version = "9.4";

    src = pkgs.requireFile {
      name = "ida-pro_94_x64linux.run";
      url = "https://my.hex-rays.com/";
      sha256 = "eabb64c3c849d3858759558359e9cebcf17e2a91bcc60523533df8b84462aa54";
    };

    license = pkgs.requireFile {
      name = "idapro.hexlic";
      url = "https://my.hex-rays.com/";
      sha256 = "fbcf5bdd56c9e8543220ac3fa71f64d6b5e406a35bab414fa568d497ff0b8d75";
    };

    patchedLibida = pkgs.requireFile {
      name = "libida.so";
      url = "https://my.hex-rays.com/";
      sha256 = "d16dffb4515157c7b2baef8c68d6df4055c1ddc4c6bc3f9da4cbadcb53aa3430";
    };

    patchedLibida32 = pkgs.requireFile {
      name = "libida32.so";
      url = "https://my.hex-rays.com/";
      sha256 = "b9695790c93a3ceaa282f6e1cdcbe58471ec532e304118803e7510a1c7e9c364";
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
      socat
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

            # Install Lumen certificate for socat TLS proxy.
            cp ${hexraysCert} $IDADIR/hexrays.crt

            # Link the binaries to the output.
            for bb in ida; do
              wrapProgram $IDADIR/$bb \
                --prefix IDADIR : $IDADIR \
                --prefix QT_PLUGIN_PATH : $IDADIR/plugins/platforms \
                --prefix PYTHONPATH : $out/bin/idalib/python \
                --prefix PATH : ${pythonForIDA}/bin:$IDADIR \
                --prefix LD_LIBRARY_PATH : $out/lib \
                --set PYTHONHOME ${pythonForIDA} \
                --set _PYTHON_SYSCONFIGDATA_NAME _sysconfigdata__linux_x86_64-linux-gnu \
                --set LUMINA_TLS false \
                --set LUMINA_HOST 127.0.0.1 \
                --set LUMINA_PORT 1234 \
                --set LUMINA_PRIMARY_TLS false \
                --set LUMINA_PRIMARY guest:guest@localhost:1234 \
                --set LUMINA_SECONDARY guest:guest@localhost:1234 \
                --set LUMINA_SECONDARY_TLS false

              # Outer shell wrapper: starts socat TLS proxy for lumen.abda.nl, then execs the C-wrapped ida.
              # makeShellWrapper is used here because makeCWrapper (used by wrapProgram) does not support --run.
              makeShellWrapper $IDADIR/$bb $out/bin/$bb \
                --run "pkill -f 'openssl:lumen.abda.nl' 2>/dev/null || true" \
                --run "${pkgs.socat}/bin/socat -s tcp4-listen:1234,fork,reuseaddr openssl:lumen.abda.nl:1235,cafile=$IDADIR/hexrays.crt &"
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
