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
                pssh = import ./nix/pssh.nix super;
                lib = super.lib // { recursiveMerge = import ./nix/recursive-merge.nix { lib = super.lib; }; };
              })
            ];
          };

          mkDockerImage = import ./nix/docker.nix;
          mkImageConfig = import ./nix/image.nix pkgs;

          digitalOceanNodeConfig = mkImageConfig {
            imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
          };

          digitalOceanHeadscaleConfig = mkImageConfig (import ./nix/headscale-config.nix pkgs);

          raspberryPi2Config = { config, ... }: mkImageConfig {
            imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix" ];
            boot.kernelPackages = pkgs.lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
          };

          raspberryPi4Config = { config, ... }: mkImageConfig {
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
              (builtins.readFile ./hosts.json)
            // builtins.mapAttrs
              (name: value: digitalOceanHeadscaleConfig)
              (builtins.fromJSON (builtins.readFile ./hosts-headscale.json));

          packages.digitalOceanImage = (pkgs.nixos (digitalOceanNodeConfig)).digitalOceanImage;
          packages.digitalOceanHeadscaleImage = (pkgs.nixos (digitalOceanHeadscaleConfig)).digitalOceanImage;
          packages.raspberryPi2Image = (pkgs.nixos (raspberryPi2Config)).sdImage;
          packages.raspberryPi4Image = (pkgs.nixos (raspberryPi4Config)).sdImage;
        });

}
