{
  lib,
  coreutils,
  writeShellApplication,
}:
# Lets coding agents inspect which keys a `.env` defines without pulling the
# secret values into a transcript that is sent to a model provider.
writeShellApplication {
  name = "env-redact";
  runtimeInputs = [coreutils];
  text = builtins.readFile ./env-redact.sh;
  meta = {
    description = "Print a .env file with its values masked, keeping keys and comments";
    mainProgram = "env-redact";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
