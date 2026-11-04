# rustup's install-time patches can reference libraries later removed by GC.
toolchains="${RUSTUP_HOME:-$HOME/.rustup}/toolchains"
[ -d "$toolchains" ] || exit 0
target="$DYNAMIC_LINKER $ZLIB_LIB"

for tc in "$toolchains"/*/; do
  tc=${tc%/}
  [ -d "$tc" ] || continue
  [ -L "$tc" ] && continue
  stamp="$tc/.nix-repatch"
  [ "$(cat "$stamp" 2>/dev/null)" = "$target" ] && continue

  ok=1
  while IFS= read -r -d "" f; do
    [ "$(head -c4 "$f")" = $'\x7fELF' ] || continue
    if interp=$(patchelf --print-interpreter "$f" 2>/dev/null) &&
      [[ $interp == /nix/store/* && $interp != "$DYNAMIC_LINKER" ]]; then
      patchelf --set-interpreter "$DYNAMIC_LINKER" "$f" || ok=0
    fi
    rpath=$(patchelf --print-rpath "$f" 2>/dev/null) || continue
    new=$(sed -E "s#/nix/store/[^:]*-zlib-[^:]*/lib#$ZLIB_LIB#g" <<<"$rpath")
    if [ "$new" != "$rpath" ]; then
      patchelf --set-rpath "$new" "$f" || ok=0
    fi
  done < <(find "$tc" -type f \( -perm -u+x -o -name '*.so*' \) -print0)

  if [ "$ok" = 1 ]; then
    printf '%s\n' "$target" >"$stamp"
  else
    echo "rustup-repatch: some files of $tc could not be patched, retrying next run" >&2
  fi
done
