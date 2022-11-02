{
  description = "my project description";

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
        in
        {
          devShells.default = pkgs.mkShell
            {
              shellHook = ''
                export PYTHONPATH=./
              '';

              buildInputs = with pkgs; [
                (poetry2nix.mkPoetryEnv
                  {
                    python = python3;
                    projectDir = ./.;

                    # editablePackageSources = {
                    #   # mpyc = if builtins.getEnv "PWD" == "" then ./. else builtins.getEnv "PWD";
                    #   mpyc = ./.;
                    # };

                    overrides = poetry2nix.overrides.withDefaults (
                      self: super: {
                        didcomm = super.didcomm.overrideAttrs (
                          old: {
                            buildInputs = old.buildInputs ++ [ super.setuptools ];
                          }
                        );
                        peerdid = super.peerdid.overrideAttrs (
                          old: {
                            buildInputs = old.buildInputs ++ [ super.setuptools ];
                          }
                        );
                        gmpy2 = python3Packages.gmpy2;
                        # gmpy2 = super.gmpy2.overrideAttrs (
                        #   old: {
                        #     buildInputs = old.buildInputs ++ [ gmp.dev mpfr.dev libmpc ];
                        #   }
                        # );
                      }
                    );
                  })
                poetry
                python3Packages.pip
                nixops
                terraform
              ];
            };

          packages.docker = buildImage pkgs "enikolov/mpyc-demo" "nix-v0.0.1";
          packages.arm = buildImage armPkgs "enikolov/mpyc-demo" "nix-armv7l-v0.0.1";
          packages.doImage = import ./deployments/do/image/image.nix { inherit pkgs inputs; };
        });
}
