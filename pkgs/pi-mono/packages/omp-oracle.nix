{
  fetchzip,
  runCommand,
}: let
  pname = "omp-oracle";
  version = "0.3.2";

  src = fetchzip {
    url = "https://registry.npmjs.org/omp-oracle/-/omp-oracle-0.3.2.tgz";
    hash = "sha512-tbP84CysABaIEaY0jwBvl/FIBIo+KSgijz11/JI0z37DOMLPXQY3d1kGKKSNkNZ2gKgvYx8kVe1gBJiBpkDCqg==";
  };

  sweetCookie = fetchzip {
    url = "https://registry.npmjs.org/@steipete/sweet-cookie/-/sweet-cookie-0.3.0.tgz";
    hash = "sha512-pJ+2dYINxlesIZkGmaTGBDU0rHZ7tyKrUUYTD5JU4rMcBosv8mgytFifWXh0Mq7LAaBjnYXrrkWhOED/0YwvxA==";
  };
in
  runCommand "${pname}-${version}" {} ''
    mkdir -p "$out"
    cp -R ${src}/. "$out"/
    mkdir -p "$out/node_modules/@steipete/sweet-cookie"
    cp -R ${sweetCookie}/. "$out/node_modules/@steipete/sweet-cookie"/
  ''
