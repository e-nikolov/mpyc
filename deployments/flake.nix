{
  description = "A very basic flake";

  inputs = rec {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      networkName = "mpyc-net";
      # pkgsFor = system: import nixpkgs {
      #   inherit system;
      #   overlays = [ self.overlay ];
      # };

    in
    {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

      packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

      nixopsConfigurations.default = {
        inherit nixpkgs;

        network.storage.legacy = {
          databasefile = "~/.nixops/deployments.nixops";
        };

        network.description = networkName;
        defaults.nixpkgs.pkgs = nixpkgs.legacyPackages.x86_64-linux;
        defaults._module.args = {
          inherit networkName;
        };

        # rpi1 =
        #   { config, pkgs, ... }:
        #   {
        #     deployment.targetHost = "pi-hole.emil-e-nikolov.gmail.com.beta.tailscale.net";
        #     deployment.targetUser = "pi";
        #   };
        resources.sshKeyPairs."mykey" = { };

        do1 = {
          services.nginx.enable = true;
          services.openssh.enable = true;

          deployment.targetEnv = "droplet";
          deployment.droplet.enableIpv6 = true;
          deployment.droplet.region = "ams2";
          deployment.droplet.size = "512mb";
        };
      };

    };
}
