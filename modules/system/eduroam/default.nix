{...}: {
  # networking.wireless = {
  #   enable = true;
  #   userControlled.enable = true;
  #   networks = {
  #     eduroam = {
  #       auth = ''
  #         ssid="eduroam"
  #         key_mgmt=WPA-EAP
  #         pairwise=CCMP
  #         group=CCMP TKIP
  #         eap=PEAP
  #         ca_cert="/home/not-matthias/.config/cat_installer/ca.pem"
  #         identity="k12104028@jku.at"
  #         altsubject_match="DNS:eduroam.jku.at"
  #         phase2="auth=MSCHAPV2"
  #         password=hash:f5993eba046bb3cfb2a8cba0bea52c67;
  #         anonymous_identity="anonymous-cat_v2@jku.at"
  #       '';
  #     };
  #   };
  # };
}
