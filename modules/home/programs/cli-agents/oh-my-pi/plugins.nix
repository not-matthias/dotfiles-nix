{pkgs}: {
  "pi-autoresearch" = {
    version = "1.6.2";
    source = pkgs.fetchzip {
      url = "https://registry.npmjs.org/pi-autoresearch/-/pi-autoresearch-1.6.2.tgz";
      hash = "sha256-2xZpgtkCz9ITeU5/71nhiB2qnOEKvlxNxmDfCg2isXE=";
    };
  };
}
