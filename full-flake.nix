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
            config = {
              allowUnsupportedSystem = true;
              allowUnfree = true;
            };
            overlays = [ (self: super: { inherit mpyc-demo; }) ];
          };
          armPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;

          modulesPath = "${pkgs.path}/nixos/modules/";
          lib = pkgs.lib;

          mkDockerImage = import ./nix/docker.nix;

          mpyc-demo = (import ./nix/mpyc-demo.nix { inherit pkgs; dir = ./.; });

          shell = import ./nix/shell.nix { inherit pkgs; };

          digitalOceanImage = import ./nix/digitalocean/image.nix {
            inherit pkgs;
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

          packages.digitalocean-image = (pkgs.nixos digitalOceanImage).digitalOceanImage;

          packages.colmena = {
            meta = {
              nixpkgs = pkgs;
            };
            defaults = digitalOceanImage;
          } // builtins.fromJSON (builtins.readFile ./hosts.json);

          packages.docker = mkDockerImage {
            inherit self pkgs;
            name = "enikolov/mpyc-demo";
            tag = "nix-v0.0.1";
            dir = ./.;
          };
          packages.arm = mkDockerImage {
            inherit self;
            pkgs = armPkgs;
            name = "enikolov/mpyc-demo";
            tag = "nix-armv7l-v0.0.1";
            dir = ./.;
          };

          packages.raspberry-pi2-image = (pkgs.nixos ({ config, lib, pkgs, modulesPath, ... }: {
            system.stateVersion = "22.11";
            imports = [
              (modulesPath + "/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix")
              {
                nix.settings = {
                  substituters = [
                    "https://cache.armv7l.xyz"
                  ];
                  trusted-public-keys = [
                    "cache.armv7l.xyz-1:kBY/eGnBAYiqYfg0fy0inWhshUo+pGFM3Pj7kIkmlBk="
                  ];
                };
              }

            ];
            boot.kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
          })).config.system.build.sdImage;
        });

}
