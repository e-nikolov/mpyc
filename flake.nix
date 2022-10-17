{
  description = "my project description";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db/master";
      flake = false;
    };
    mach-nix = {
      url = "mach-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    nixImage.url = "github:nixos/nix/master";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, pypi-deps-db, nixImage }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonEnv = mach-nix.lib."${system}".mkPython {
          requirements = builtins.readFile ./requirements.txt;
        };
        mpyc = pkgs.python3Packages.buildPythonPackage {
          # name = "mpyc";
          pname = "mpyc";
          version = "0.8.8";
          src = ./.;
        };
        mpycDocker = mach-nix.lib.${system}.buildPythonPackage {
          # name = "mpyc";
          pname = "mpyc";
          version = "0.8.8";
          src = ./.;
        };

        pythonDockerEnv = mach-nix.lib."${system}".mkPython {
          requirements = builtins.readFile ./requirements.txt;

          packagesExtra = [ mpycDocker ];
        };

        baseImage = pkgs.dockerTools.pullImage {
          imageName = "nixos/nix";
          imageDigest =
            "sha256:85299d86263a3059cf19f419f9d286cc9f06d3c13146a8ebbb21b3437f598357";
          sha256 = "19fw0n3wmddahzr20mhdqv6jkjn1kanh6n2mrr08ai53dr8ph5n7";
          finalImageTag = "2.2.1";
          finalImageName = "nix";
        };
      in {

        packages.image = pkgs.dockerTools.buildLayeredImage {
          name = "mpyc-demo";
          tag = "0.0.1";
          created = builtins.substring 0 8 self.lastModifiedDate;

          contents = with pkgs;
            [
              bashInteractive
              coreutils-full
              which
              curl
              less
              wget
              man
              findutils
              cacert.out
              gnugrep
              gzip
              gnutar
              nix
            ] ++ [ pythonEnv ./. mpyc ];
        };

        packages.docker = pkgs.dockerTools.buildLayeredImage {
          name = "mpyc-demo";
          tag = "0.0.1";
          created = builtins.substring 0 8 self.lastModifiedDate;
          # fromImage = nixImage.hydraJobs.dockerImage;
          fromImage = baseImage;
          contents = pkgs.buildEnv {
            name = "image-root";
            pathsToLink = [ "/bin" ];
            paths = with pkgs;
              [
                bashInteractive

                # coreutils-full
                # which
                # curl
                # less
                # wget
                # man
                # findutils
                # cacert.out
                # gnugrep
                # gzip
                # gnutar
                # nix
              ] ++ [
                pythonEnv
                # mpyc
                ./.
                # mpyc
              ];
          };

          config = {
            # Cmd = [ "bash" "-c" "python" "./demos/secretsanta.py" ];
            # WorkingDir = "/home";
            # Entrypoint = [ "/bin/bash" "-c" ];
            # Env = [ "SHELL=/bin/bash" ];
          };
        };

        packages.docker2 = pkgs.dockerTools.buildLayeredImage {
          name = "mpyc-demo";
          tag = "0.0.1";
          created = builtins.substring 0 8 self.lastModifiedDate;
          # fromImage = nixImage.hydraJobs.dockerImage;
          fromImage = baseImage;

          contents = [
            pkgs.bashInteractive
            pythonDockerEnv
            (pkgs.buildEnv {
              name = "demos";
              paths = [ ./. ];
              pathsToLink = [ "/demos" ];
            })
          ];

          config = {
            Cmd = [ "bash" "-c" "python" "./demos/secretsanta.py" ];
            Entrypoint = [ "/bin/bash" "-c" ];
          };
        };

        packages.docker3 = pkgs.dockerTools.buildLayeredImage {
          name = "mpyc-demo";
          tag = "0.0.1";
          created = builtins.substring 0 8 self.lastModifiedDate;
          # fromImage = nixImage.hydraJobs.dockerImage;
          fromImage = baseImage;
          # contents = pkgs.buildEnv {
          #   name = "image-root";
          #   pathsToLink = [ "/bin" ];
          #   paths = with pkgs;
          #     [
          #       bashInteractive

          #       coreutils-full
          #       which
          #       curl
          #       less
          #       wget
          #       man
          #       findutils
          #       cacert.out
          #       gnugrep
          #       gzip
          #       gnutar
          #       nix
          #     ] ++ [
          #       pythonEnv
          #       # mpyc
          #       ./.
          #       # mpyc
          #     ];
          # };

          config = {
            Cmd = [ "bash" "-c" "python" "./demos/secretsanta.py" ];
            # Env = [ "SHELL=/bin/bash" ];
          };
        };

        devShell = pkgs.mkShell {

          buildInputs = [ pythonEnv mpyc pkgs.ansible ];
          # shellHook = "";
        };
      });
  # outputs = { self, nixpkgs, flake-utils, mach-nix }:
  #   flake-utils.lib.eachDefaultSystem (system:
  #     let pkgs = nixpkgs.legacyPackages.${system};
  #     in {
  #       aa = builtins.traceVal mach-nix;
  #       devShells.default = import ./shell.nix { inherit pkgs mach-nix; };
  #     });
}
