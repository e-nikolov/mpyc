{
  description = "my project description";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    # nixpkgs.crossSystem.config = "armv7l-linux";
    flake-utils.url = "github:numtide/flake-utils";
    # pypi-deps-db = { url = "github:DavHau/pypi-deps-db/master"; };
    mach-nix = {
      url = "mach-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      # inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    # nixImage.url = "github:nixos/nix/master";
  };


  outputs = { self, flake-utils, nixpkgs, mach-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # nixpkgs.crossSystem.config = "armv7l-hf-multiplatform";

        # pkgs = nixpkgs.legacyPackages.${system}.pkgsCross.armv7l-hf-multiplatform;
        pkgs = nixpkgs.legacyPackages.${system};

        baseImage = pkgs.pkgsCross.raspberryPi.dockerTools.pullImage {
          imageName = "nixos/nix";
          imageDigest =
            "sha256:85299d86263a3059cf19f419f9d286cc9f06d3c13146a8ebbb21b3437f598357";
          sha256 = "19fw0n3wmddahzr20mhdqv6jkjn1kanh6n2mrr08ai53dr8ph5n7";
          finalImageTag = "2.2.1";
          finalImageName = "nix";
        };
      in
      with pkgs; {

        devShells.default = mkShell
          {
            buildInputs = [ zlib ]; # your dependencies here
          };

        packages.default = pkgs.buildEnv {
          name = "arm";
          paths = [
            # pkgs.pkgsCross.raspberryPi.hello
            pkgs.pkgsCross.raspberryPi.hello
            pkgs.pkgsCross.armv7l-hf-multiplatform.nix
          ];
        };

        packages.image = pkgs.pkgsCross.raspberryPi.dockerTools.buildLayeredImage
          {
            name = "enikolov/mpyc-demo-arm";
            tag = "0.0.1";
            created = builtins.substring 0 8 self.lastModifiedDate;
            # arch = "linux/arm/v7";
            fromImage = baseImage;


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
                paths = [ ../../. ];
                pathsToLink = [ "/demos" ];
              })
            ];

            config = {
              Cmd = [ "hello" ];
              # Entrypoint = [ "/bin/bash" "-c" ];
            };
          };
      });
}
