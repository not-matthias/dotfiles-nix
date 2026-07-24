{
  lib,
  buildGoModule,
  fetchFromGitHub,
  libx11,
  makeWrapper,
}:
buildGoModule rec {
  pname = "slk";
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "gammons";
    repo = "slk";
    tag = "v${version}";
    hash = "sha256-Mns5HBBz5iql/AhlZxFEK/VcPn3TPID+RgPwsGwOgvs=";
  };

  vendorHash = "sha256-dPa469oNv6eYyDdly3uhc273DAGz+erc0E3K/am7WoY=";

  subPackages = ["cmd/slk"];

  # golang.design/x/clipboard requires CGO on Linux: its nocgo stub
  # hard-panics ("cannot use when CGO_ENABLED=0") on any clipboard op.
  # Upstream's goreleaser builds CGO_ENABLED=0, so every official Linux
  # release tarball crashes on drag-select-copy. buildGoModule already
  # sets CGO_ENABLED=1 by default here; leaving it on removes the panic
  # path entirely, and clipboard then works over XWayland
  # (xwayland-satellite bridges the X11 selection to Wayland).

  # clipboard_linux.c #include <X11/Xlib.h> / <X11/Xatom.h> for type
  # definitions only -- the X11 functions are dlsym'd at runtime, so
  # only the headers are needed at build time (no -lX11 link).
  buildInputs = [libx11];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.commit=f60601f9bdabb868a747365ad41e4a698c163596"
  ];

  nativeBuildInputs = [makeWrapper];

  # clipboard_linux.c dlopen("libX11.so") (bare soname, no .6 suffix)
  # at runtime. NixOS has no global libX11.so and the dev output's
  # symlink has a relative target that won't resolve, so provide an
  # absolute libX11.so -> libX11.so.6 in the package and expose it via
  # LD_LIBRARY_PATH. libX11.so.6's own RUNPATH resolves its deps
  # (libxcb, libXau, ...).
  postFixup = ''
    mkdir -p $out/lib
    ln -s ${lib.getLib libx11}/lib/libX11.so.6 $out/lib/libX11.so
    wrapProgram $out/bin/slk --prefix LD_LIBRARY_PATH : $out/lib
  '';

  meta = with lib; {
    description = "A blazingly fast, keyboard-driven Slack TUI";
    homepage = "https://github.com/gammons/slk";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "slk";
  };
}
