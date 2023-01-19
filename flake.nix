{
  description = "MPyC flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/master";

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
          };

          mpyc-demo = (import ./nix/mpyc-demo.nix { inherit pkgs; dir = ./.; });

          shell = import ./nix/shell.nix { inherit pkgs; };

          mkImageConfig = import ./nix/image.nix;

          digitalOceanConfig = mkImageConfig {
            inherit pkgs;
            imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
            extraPackages = [ mpyc-demo ];
          };

          raspberryPi2Config = { config, ... }: mkImageConfig
            {
              inherit pkgs;
              imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix" ];
              extraPackages = [ mpyc-demo ];
            } // {
            boot.kernelPackages = pkgs.lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
          };

          raspberryPi4Config = { config, ... }: mkImageConfig
            {
              inherit pkgs;
              imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix" ];
              extraPackages = [ mpyc-demo ];
            };
        in
        {
          devShells.default = pkgs.mkShell {
            shellHook = ''
              export PYTHONPATH=./
            '';

            nativeBuildInputs = with pkgs; [
              mpyc-demo
              poetry
              python3Packages.pip
              curl
              jq
              colmena
              pssh

              (terraform.withPlugins
                (tp: [
                  tp.digitalocean
                  tp.null
                  tp.external
                  tp.tailscale
                  tp.random
                ]))
            ];
          };

          packages.colmena = {
            meta = {
              nixpkgs = pkgs;
            };
            defaults = digitalOceanConfig;
          } // builtins.fromJSON (builtins.readFile ./hosts.json);

          packages.digitalOceanImage = (pkgs.nixos (digitalOceanConfig)).digitalOceanImage;

          packages.raspberryPi2Image = (pkgs.nixos (raspberryPi2Config)).sdImage;

          packages.raspberryPi4Image = (pkgs.nixos (raspberryPi4Config)).sdImage;
        });

}
