{
  network.description = "Test server";

  testserver = { config, pkgs, ... }: {

    services.openssh.enable = true;


    # Web server
    networking.firewall.allowedTCPPorts = [ 22 4343 8080 ];
    services.nginx = {
      enable = true;
      virtualHosts."localhost" = {
        root = "/www/webroot";
        listen = [
          { addr = "0.0.0.0"; port = 4343; ssl = true; }
          { addr = "0.0.0.0"; port = 8080; }
        ];

      };
    };

  };

}
