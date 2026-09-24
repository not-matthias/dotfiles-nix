{
  stdenvNoCC,
  lib,
  fetchurl,
  makeWrapper,
  nodejs_22,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "greptile";
  version = "3.5.4";

  src = fetchurl {
    url = "https://registry.npmjs.org/greptile/-/greptile-${finalAttrs.version}.tgz";
    hash = "sha512-3n+jLOT9WB+8zv2XdTEAXPzMGWH0ybwVdJZrr1/b8UKGpi7u3vq5dVBwp3MCaNgzkaIVgzqfXKXZDp1iBVmjrw==";
  };

  nativeBuildInputs = [makeWrapper];

  # The npm tarball ships a self-contained bundle with no runtime dependencies.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/greptile $out/bin
    cp -r . $out/lib/greptile
    makeWrapper ${lib.getExe nodejs_22} $out/bin/greptile \
      --add-flags $out/lib/greptile/dist/greptile.js

    runHook postInstall
  '';

  meta = {
    description = "Greptile CLI for AI code review";
    homepage = "https://www.greptile.com/docs/code-review/greptile-cli";
    license = lib.licenses.mit;
    mainProgram = "greptile";
    platforms = lib.platforms.unix;
  };
})
