{
  description = "my project description";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pypi-deps-db = { url = "github:DavHau/pypi-deps-db/master"; };
    mach-nix = {
      url = "github:e-nikolov/mach-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    nixImage.url = "github:nixos/nix/master";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, pypi-deps-db, nixImage }:

    flake-utils.lib.eachSystem (flake-utils.lib.defaultSystems ++ [ flake-utils.lib.system.armv7l-linux ])
      (system:
        let

          # nixpkgs.crossSystem.system = "armv7l-linux";
          pkgs = nixpkgs.legacyPackages.${system};

          mpyc = {
            pname = "mpyc";
            version = "0.8.8";
            src = ./.;
          };
          requirements = builtins.readFile ./requirements.txt;

          baseImage = pkgs.dockerTools.pullImage {
            imageName = "nixos/nix";
            imageDigest =
              "sha256:85299d86263a3059cf19f419f9d286cc9f06d3c13146a8ebbb21b3437f598357";
            sha256 = "19fw0n3wmddahzr20mhdqv6jkjn1kanh6n2mrr08ai53dr8ph5n7";
            finalImageTag = "2.2.1";
            finalImageName = "nix";
          };
        in
        {
          devShells.default = pkgs.python3Packages.buildPythonPackage {
            inherit (mpyc) pname version src;
            propagatedBuildInputs =
              [ (mach-nix.lib.${system}.mkPython { inherit requirements; }) ];
          };

          devShells.dev = pkgs.mkShell {
            buildInputs =
              [ (mach-nix.lib.${system}.mkPython { inherit requirements; }) ];

            shellHook = ''
              echo 456
              pip install -e .
            '';
            postShellHook = ''
              echo 123
              pip install -e .
            '';
          };

          devShells.ops = pkgs.mkShell { buildInputs = [ pkgs.ansible ]; };

          packages.default = pkgs.dockerTools.buildLayeredImage {
            name = "enikolov/mpyc-demo";
            tag = "0.0.1";
            created = builtins.substring 0 8 self.lastModifiedDate;
            # fromImage = baseImage;


            contents = [
              pkgs.bashInteractive
              (mach-nix.lib.x86_64-linux.mkPython {
                inherit requirements;
                packagesExtra =
                  [ (mach-nix.lib.armv7l-linux.buildPythonPackage mpyc) ];
              })
              (pkgs.buildEnv {
                name = "demos";
                paths = [ ./. ];
                pathsToLink = [ "/demos" ];
              })
            ];

            config = {
              Cmd = [ "python ./demos/secretsanta.py" ];
              Entrypoint = [ "/bin/bash" "-c" ];
            };
          };

          packages.arm = pkgs.pkgsCross.raspberryPi.dockerTools.buildLayeredImage
            {
              name = "enikolov/mpyc-demo-arm";
              tag = "0.0.1";
              created = builtins.substring 0 8 self.lastModifiedDate;
              # arch = "linux/arm/v7";
              # fromImage = baseImage;


              contents = [
                # (mach-nix.lib.raspberryPi.mkPython {
                #   inherit requirements;
                #   packagesExtra =
                #     [ (mach-nix.lib.armv7l-linux.buildPythonPackage mpyc) ];
                # })

                pkgs.pkgsCross.raspberryPi.hello
                pkgs.pkgsCross.raspberryPi.python3
                pkgs.pkgsCross.raspberryPi.coreutils
                pkgs.pkgsCross.raspberryPi.bashInteractive
                pkgs.pkgsCross.raspberryPi.nix
                pkgs.pkgsCross.raspberryPi.which
                pkgs.pkgsCross.raspberryPi.curl

                (pkgs.buildEnv {
                  name = "demos";
                  paths = [ ./. ];
                  pathsToLink = [ "." ];
                })
              ];

              config = {
                Cmd = [ "hello" ];
                # Entrypoint = [ "/bin/bash" "-c" ];
              };
            };
        });
}
