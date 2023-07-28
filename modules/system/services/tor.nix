{...}: {
  services.tor = {
    enable = true;
    enableGeoIP = false;
    relay.onionServices = {
      jku_onion = {
        version = 3;
        secretKey = "/home/not-matthias/Documents/jkujkgocurr5dwszu5ufsdmbwlrkr7hcbw26u343zeezmuovtsp5onid.onion/hs_ed25519_secret_key";
        map = [
          {
            port = 80;
            target = {
              addr = "[::1]";
              port = 9009;
            };
          }
        ];
      };
    };
    # settings = {
    #   ClientUseIPv4 = false;
    #   ClientUseIPv6 = true;
    #   ClientPreferIPv6ORPort = true;
    # };
  };
}
