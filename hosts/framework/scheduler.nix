{
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
    extraArgs = [
      "--primary-domain"
      "performance"
    ];
  };
}
