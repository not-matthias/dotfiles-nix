final: prev: {
  jetbrains =
    prev.jetbrains
    // {
      # Get info from site...
      copilot-plugin-info = final.jetbrains.plugins.getUrl {
        id = "17718";
        hash = "sha256-V2DHAjPOEU5HecSqf+h+9xpc6N0ouJX05f0BitY9p7Q=";
      };
      # Actually build the plugin
      copilot-plugin = final.jetbrains.plugins.urlToDrv (final.jetbrains.copilot-plugin-info
        // {
          hash = "sha256-emHd2HLNVgeR9yIGidaE76KWTtvilgT1bieMEn6lDIk=";
          extra = {
            inputs = [prev.patchelf prev.glibc prev.gcc-unwrapped];
            commands = let
              libPath = prev.lib.makeLibraryPath [prev.glibc prev.gcc-unwrapped];
            in ''
              agent="copilot-agent/bin/copilot-agent-linux"
              orig_size=$(stat --printf=%s $agent)
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $agent
              patchelf --set-rpath ${libPath} $agent
              chmod +x $agent
              new_size=$(stat --printf=%s $agent)
              # https://github.com/NixOS/nixpkgs/pull/48193/files#diff-329ce6280c48eac47275b02077a2fc62R25
              ###### zeit-pkg fixing starts here.
              # we're replacing plaintext js code that looks like
              # PAYLOAD_POSITION = '1234                  ' | 0
              # [...]
              # PRELUDE_POSITION = '1234                  ' | 0
              # ^-----20-chars-----^^------22-chars------^
              # ^-- grep points here
              #
              # var_* are as described above
              # shift_by seems to be safe so long as all patchelf adjustments occur
              # before any locations pointed to by hardcoded offsets
              var_skip=20
              var_select=22
              shift_by=$(expr $new_size - $orig_size)
              function fix_offset {
                # $1 = name of variable to adjust
                location=$(grep -obUam1 "$1" $agent | cut -d: -f1)
                location=$(expr $location + $var_skip)
                value=$(dd if=$agent iflag=count_bytes,skip_bytes skip=$location \
                  bs=1 count=$var_select status=none)
                value=$(expr $shift_by + $value)
                echo -n $value | dd of=$agent bs=1 seek=$location conv=notrunc
              }
              fix_offset PAYLOAD_POSITION
              fix_offset PRELUDE_POSITION
            '';
          };
        });
      # Control the version of Intellij ourselves and add the plugin.
      idea-ultimate = prev.jetbrains.idea-ultimate.overrideAttrs (old: rec {
        version = "2022.2.3";
        src = prev.fetchurl {
          url = "https://download.jetbrains.com/idea/ideaIU-${version}-no-jbr.tar.gz";
          sha256 = "dFTX4Lj049jYBd3mRdKLhCEBvXeuqLKRJYgMWS5rjIU=";
        };
        plugins = [final.jetbrains.copilot-plugin];
      });
    };
}
