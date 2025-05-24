# References:
# - https://git.eisfunke.com/config/nixos/-/blob/e7c25e9b57b71cad66db10d939c5a45e1c46efcf/home/age.nix
# - https://github.com/ryantm/agenix/issues/50#issuecomment-1634714797
{user, ...}: {
  age = {
    # Normally agenix uses $XDG_RUNTIME_DIR as secretsDir. This *would* be fine, but the variable
    # isn't replaced in the path variables of the secrets, and e.g. the Nix config file doesn't accept
    # env variables in paths. So I instead set a fixed path without env variables for the secrets.
    #
    # secretsMountPoint can stay as is though, as this path won't be inserted in configs.
    #
    # secretsDir = "/home/${user}/.agenix";
    identityPaths = ["/home/${user}/.ssh/id_rsa"];

    # TODO: Create a helper function to create those entries
    secrets = {
      "temp1".file = ../../../secrets/temp1.age;
      "duckdns".file = ../../../secrets/duckdns.age;
    };
  };
}
