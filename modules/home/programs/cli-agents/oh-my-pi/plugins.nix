{pkgs}: {
  "@dietrichgebert/ponytail" = {
    version = "4.9.0";
    source = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@dietrichgebert/ponytail/-/ponytail-4.9.0.tgz";
      hash = "sha256-WfXskMTS9ICaTgsyAhtevMclVignhtlbGWFF+GvNEZ8=";
    };
  };
  "pi-autoresearch" = {
    version = "1.6.2";
    source = pkgs.fetchzip {
      url = "https://registry.npmjs.org/pi-autoresearch/-/pi-autoresearch-1.6.2.tgz";
      hash = "sha256-2xZpgtkCz9ITeU5/71nhiB2qnOEKvlxNxmDfCg2isXE=";
    };
  };
  "pi-caveman" = {
    version = "1.0.8";
    source = pkgs.fetchzip {
      url = "https://registry.npmjs.org/pi-caveman/-/pi-caveman-1.0.8.tgz";
      hash = "sha256-IEryQnCI7PW54GMeqpNIBqozka+v7n9/QNuc9p8bLP0=";
    };
  };
}
