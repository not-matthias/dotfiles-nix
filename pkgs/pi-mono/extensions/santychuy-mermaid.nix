{
  fetchFromGitHub,
  runCommand,
}: let
  src = fetchFromGitHub {
    owner = "santychuy";
    repo = "pi-setup";
    rev = "0a0692fffea3c83725e7cae7219cb0699fb2f8a4";
    hash = "sha256-BPJxfRmmrgxS8k9melTmHRMzwlfHuyukSKxGyIUxifM=";
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
