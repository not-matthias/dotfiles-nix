{
  flakes,
  user,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit flakes user;
      #   addons = nur.repos.rycee.firefox-addons;
    };
    users.${user} = {
      imports = [
        ./home.nix
        # spicetify-nix.homeManagerModule
      ];
    };
  };
}
