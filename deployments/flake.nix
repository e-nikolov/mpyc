{
  description = "A very basic flake";

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

        rpi1 =
          { config, pkgs, ... }:
          {
            deployment.targetHost = "pi-hole.emil-e-nikolov.gmail.com.beta.tailscale.net";
            deployment.targetUser = "pi";
          };
        # webserver = import ./machine;
      };

    };
}
