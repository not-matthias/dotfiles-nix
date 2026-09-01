{
  fetchFromGitHub,
  runCommand,
}: let
  src = fetchFromGitHub {
    owner = "santychuy";
    repo = "pi-setup";
    rev = "c4bd7b9d459bc510283b91202449abb4c2f7bfc6";
    hash = "sha256-OH8LFW7PWwdi13Hd99vZTuOdsSeK2priaBo2AhDOOOM=";
  };
in
  runCommand "santychuy-mermaid-src" {} ''
    mkdir -p $out
    cp -R ${src}/extensions/mermaid/. $out/
    chmod -R +w $out
    substituteInPlace $out/index.ts \
      --replace-fail 'return message.includes("DOMPurify");' 'return message.includes("DOMPurify") || message.includes("purify.addHook");'
    cp ${./santychuy-mermaid-package-lock.json} $out/package-lock.json
  ''
