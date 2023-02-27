pkgs: {
  imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
  environment.systemPackages = [
    pkgs.headscale
  ];

  services = {
    headscale.package = pkgs.headscale;
    headscale.enable = true;
    headscale.settings = {
      metrics_listen_addr = "127.0.0.1:9090";
      listen_addr = "0.0.0.0:8080";
      log = {
        level = "debug";
      };
      ip_prefixes = [
        "100.64.0.0/10"
      ];
      dns_config = {
        override_local_dns = true;
        # domains = [ "headnet.ts" ];
        base_domain = "headnet.ts";
      };
    };
  };
}
