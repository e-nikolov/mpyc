{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      mpyc-demo = (import ./nix/mpyc-demo.nix { inherit pkgs; dir = ./.; });

      pkgs = import nixpkgs {
        system = "aarch64-linux";
      };

      digitalOceanConfig = import ./nix/digitalocean/image.nix {
        inherit pkgs;
        extraPackages = [ mpyc-demo ];
      };
    in
    {
      packages.digitalOceanImage = (pkgs.nixos digitalOceanConfig).digitalOceanImage;

      packages.raspberryPi2Image = (pkgs.nixos ({ config, ... }: {
        system.stateVersion = "22.11";
        imports = [
          ("${pkgs.path}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix")
          # {
          #   nix.settings = {
          #     substituters = [
          #       "https://cache.armv7l.xyz"
          #     ];
          #     trusted-public-keys = [
          #       "cache.armv7l.xyz-1:kBY/eGnBAYiqYfg0fy0inWhshUo+pGFM3Pj7kIkmlBk="
          #     ];
          #   };
          # }

        ];
        # boot.kernelPackages = pkgs.lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
      })).sdImage;

      packages.raspberryPi4Image = (pkgs.nixos ({ config, ... }: {
        system.stateVersion = "22.11";
        imports = [
          ("${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix")
        ];
      })).sdImage;

      packages.colmena = {
        meta = {
          nixpkgs = pkgs;
        };
        defaults = digitalOceanConfig;
      } // builtins.fromJSON (builtins.readFile ./hosts.json);
    };
}
