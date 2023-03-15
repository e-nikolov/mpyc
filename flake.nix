{
  description = "MPyC flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/main";

    poetry2nix = {
      url = "github:nix-community/poetry2nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    { colmena = self.packages.x86_64-linux.colmena; }
    //
    flake-utils.lib.eachSystem (flake-utils.lib.defaultSystems ++ [ flake-utils.lib.system.armv7l-linux ])
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # config = {
            #   allowUnsupportedSystem = true;
            #   allowUnfree = true;
            # };
            overlays = [
              (self: super: {
                mpyc-demo = import ./nix/mpyc-demo.nix super ./.;
                pwnat = import ./nix/pwnat.nix super;
                tailscale = import ./nix/tailscale.nix super;
                headscale = import ./nix/headscale.nix super;
                natpunch = import ./nix/natpunch.nix super;
                gole = import ./nix/gole.nix super;
                go-stun = import ./nix/go-stun.nix super;
                pion-stun = import ./nix/pion-stun.nix super;
                pssh = import ./nix/pssh.nix super;
                mkDockerImage = import ./nix/docker.nix;
                mkImageConfig = import ./nix/image.nix self;
                lib = super.lib // { recursiveMerge = import ./nix/recursive-merge.nix { lib = super.lib; }; };
              })
            ];
          };

          digitalOceanNodeConfig = pkgs.mkImageConfig {
            imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
          };

          digitalOceanHeadscaleConfig = pkgs.mkImageConfig (import ./nix/headscale-config.nix pkgs);

          raspberryPi2Config = { config, ... }: pkgs.mkImageConfig {
            imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix" ];
            boot.kernelPackages = pkgs.lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
          };

          raspberryPi4Config = { config, ... }: pkgs.mkImageConfig {
            imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix" ];
          };
        in
        {
          devShells.default = import ./nix/shell.nix pkgs;

          packages.colmena =
            {
              meta = {
                nixpkgs = pkgs;
              };
              defaults = digitalOceanNodeConfig;
            } // builtins.fromJSON
              (builtins.readFile ./hosts-dns.json)
            // builtins.mapAttrs
              (name: value: digitalOceanHeadscaleConfig)
              (builtins.fromJSON (builtins.readFile ./hosts-headscale-dns.json));

          packages.digitalOceanImage = (pkgs.nixos (digitalOceanNodeConfig)).digitalOceanImage;
          packages.digitalOceanHeadscaleImage = (pkgs.nixos (digitalOceanHeadscaleConfig)).digitalOceanImage;
          packages.raspberryPi2Image = (pkgs.nixos (raspberryPi2Config)).sdImage;
          packages.raspberryPi4Image = (pkgs.nixos (raspberryPi4Config)).sdImage;
        });
}
