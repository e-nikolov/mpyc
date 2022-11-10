{
  description = "my project description";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/master";
    # flake-utils.inputs.nixpkgs.follows = "nixpkgs";

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
          # nixpkgs.crossSystem.system = "armv7l-linux";
          # pkgs = nixpkgs.legacyPackages.${system};
          pkgs = import nixpkgs {
            inherit system;
            config = {
              permittedInsecurePackages = [
                "python2.7-pyjwt-1.7.1"
              ];
              allowUnfree = true;
            };
          };


          # armPkgs = pkgs.pkgsCross.raspberryPi;
          armPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;

          # pkgs = import nixpkgs { inherit system; overlays = [ poetry2nix.overlay ]; };

          buildImage = import ./nix/docker.nix;

          python-mpyc = (import ./nix/python-mpyc.nix { inherit pkgs; dir = ./.; });

          shellAttrs = {
            shellHook = ''
              export PYTHONPATH=./
            '';

            nativeBuildInputs = with pkgs; [
              python-mpyc
              poetry
              python3Packages.pip
              curl
              # bashInteractive
              # bash-completion

            ];
          };
          mkDigitalOceanImage = import ./deployments/digitalocean/image.nix;

          modulesPath = "${pkgs.path}/nixos/modules/";
          lib = pkgs.lib;
        in
        {
          devShells.default = pkgs.mkShell shellAttrs;


          devShells.ops = (pkgs.mkShell (pkgs.lib.recursiveUpdate shellAttrs {
            nativeBuildInputs = with pkgs; [
              (terraform.withPlugins
                (tp: [ tp.digitalocean tp.null tp.external tp.tailscale ]))
              (pkgs.writeShellScriptBin "ter" ''
                terraform $@ && terraform show -json > show.json
              '')
              jq
              arion
              pkgs.colmena
            ];

            shellHook = ''
              # complete -o nospace -C /nix/store/zbzv9x7y2z690pj4kwpq1f4lak47w9f9-terraform-1.3.3/bin/terraform terraform

              export PYTHONPATH=./
            '';
          }));

          packages.docker = buildImage
            {
              inherit self pkgs;
              name = "enikolov/mpyc-demo";
              tag = "nix-v0.0.1";
              dir = ./.;
            };
          packages.arm = buildImage
            {
              inherit self;
              pkgs = armPkgs;
              name = "enikolov/mpyc-demo";
              tag = "nix-armv7l-v0.0.1";
              dir = ./.;
            };

          packages.digitalocean-image = (pkgs.nixos (mkDigitalOceanImage {
            inherit pkgs lib modulesPath;
          })).digitalOceanImage;

          packages.colmena = {
            meta = {
              nixpkgs = pkgs;
            };

            defaults = { pkgs, lib, modulesPath, ... }: mkDigitalOceanImage {
              inherit pkgs modulesPath lib;
              extraPackages = [ python-mpyc ];
            };
          } // builtins.fromJSON (builtins.readFile ./hosts.json);

          packages.arionTest = import ./deployments/arion/arion-compose.nix;
        });

}
