{
  description = "my project description";

  inputs = rec {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils/master";
    pypi-deps-db = { url = "github:DavHau/pypi-deps-db/master"; };
    mach-nix = {
      url = "github:e-nikolov/mach-nix/master";
      # url = "mach-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # nixImage.url = "github:nixos/nix/master";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, poetry2nix, ... }:
    flake-utils.lib.eachSystem (flake-utils.lib.defaultSystems ++ [ flake-utils.lib.system.armv7l-linux ])
      # flake-utils.lib.eachSystem (flake-utils.lib.defaultSystems)
      (system:
        let

          # nixpkgs.crossSystem.system = "armv7l-linux";
          pkgs = nixpkgs.legacyPackages.${system};
          # armPkgs = pkgs.pkgsCross.raspberryPi;
          armPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;

          # pkgs = import nixpkgs { inherit system; overlays = [ poetry2nix.overlay ]; };

          mpyc = {
            name = "mpyc";
            # pname = "mpyc";
            # version = "0.8.8";
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

          nonRootShadowSetup = { user, uid, gid ? uid }: with pkgs; [
            (
              writeTextDir "etc/shadow" ''
                root:!x:::::::
                ${user}:!:::::::
              ''
            )
            (
              writeTextDir "etc/passwd" ''
                root:x:0:0::/root:${runtimeShell}
                ${user}:x:${toString uid}:${toString gid}::/home/${user}:
              ''
            )
            (
              writeTextDir "etc/group" ''
                root:x:0:
                ${user}:x:${toString gid}:
              ''
            )
            (
              writeTextDir "etc/gshadow" ''
                root:x::
                ${user}:x::
              ''
            )
          ];

          buildImage = pkgs: pkgs.dockerTools.buildLayeredImage
            {
              name = "enikolov/mpyc-demo-arm";
              tag = "0.0.1";
              created = builtins.substring 0 8 self.lastModifiedDate;
              # arch = "linux/arm/v7";
              # fromImage = baseImage;

              contents = pkgs.buildEnv
                {
                  name = "zzz-python-env-123";
                  paths = [
                    (pkgs.poetry2nix.mkPoetryEnv
                      # (pkgs.poetry2nix.mkPoetryApplication
                      # (pkgs.poetry2nix.mkPoetryPackages
                      {
                        python = pkgs.python3;
                        projectDir = ./.;

                        editablePackageSources = {
                          # mpyc = if builtins.getEnv "PWD" == "" then ./. else builtins.getEnv "PWD";
                          mpyc = null;
                        };
                        extraPackages = (ps: [
                          (pkgs.python3Packages.buildPythonPackage
                            {
                              # inherit (mpyc) pname version src;
                              name = "mpyc";
                              src = ./.;
                            })
                        ]);

                        overrides = pkgs.poetry2nix.overrides.withDefaults (
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
                            gmpy2 = pkgs.python3Packages.gmpy2;
                            # gmpy2 = super.gmpy2.overrideAttrs (
                            #   old: {
                            #     buildInputs = old.buildInputs ++ [ pkgs.gmp.dev pkgs.mpfr.dev pkgs.libmpc ];
                            #   }
                            # );
                          }
                        );
                      })
                    # pkgs.poetry
                    # # pkgs.python3
                    # pkgs.python3Packages.pip
                    # # pkgs.hello
                    # pkgs.gnugrep
                    # # pkgs.python3
                    # pkgs.coreutils
                    # pkgs.bashInteractive
                    # pkgs.nix
                    # pkgs.which
                    # pkgs.curl
                    # pkgs.gnumake
                    # pkgs.zsh
                    # pkgs.fzf
                    # pkgs.fzf-zsh
                    # pkgs.gawk
                    # pkgs.unixtools.nettools
                    # pkgs.unixtools.ping
                    # pkgs.unixtools.top
                    # pkgs.wget
                    # pkgs.htop


                    # (pkgs.buildEnv {
                    #   name = "demos";
                    #   paths = [ ./. ];
                    #   pathsToLink = [ "/demos" ];
                    # })
                    (pkgs.buildEnv {
                      name = "mpyc-root";
                      paths = [ ./. ];
                      # pathsToLink = [ "/demos" ];
                      extraPrefix = "/mpyc";

                      buildInputs = [
                        # pkgs.poetry
                        # pkgs.pythonPackages.venvShellHook
                      ];
                      # postVenvCreation = ''
                      #   unset SOURCE_DATE_EPOCH
                      #   pip install -r requirements.txt
                      # '';

                      # shellHook = ''
                      #   ls -al
                      #   poetry install
                      # '';
                      # postShellHook = ''
                      #   poetry install
                      # '';
                    })

                    # (runCommand "poetry-install" { } ''
                    #   mkdir -p $out/share/android-sdk/build-tools/32.0.0/lib/
                    #   ln -s \
                    #     ${android-sdk}/share/android-sdk/build-tools/32.0.0/lib/d8.jar \
                    #     $out/share/android-sdk/build-tools/32.0.0/lib/dx.jar
                    #   ln -s \
                    #     ${android-sdk}/share/android-sdk/build-tools/32.0.0/d8 \
                    #     $out/share/android-sdk/build-tools/32.0.0/dx
                    # '')

                    (pkgs.buildEnv {
                      name = "docker-home";
                      paths = [ ./docker-home ];
                      pathsToLink = [ "/" ];
                      extraPrefix = "/root";
                    })
                  ] ++ nonRootShadowSetup {
                    uid = 999;
                    user = "somebody";
                  };
                };

              # contents = [
              #   # (mach-nix.lib.raspberryPi.mkPython {
              #   #   inherit requirements;
              #   #   packagesExtra =
              #   #     [ (mach-nix.lib.armv7l-linux.buildPythonPackage mpyc) ];
              #   # })

              #   (pkgs.python3Packages.buildPythonPackage
              #     {
              #       # inherit (mpyc) pname version src;
              #       name = "mpyc";
              #       src = ./.;
              #     })

              #   pkgs.hello
              #   pkgs.gnugrep
              #   pkgs.python3
              #   pkgs.coreutils
              #   pkgs.bashInteractive
              #   pkgs.nix
              #   pkgs.which
              #   pkgs.curl
              #   pkgs.python3Packages.pip

              #   (pkgs.buildEnv {
              #     name = "demos";
              #     paths = [ ./. ];
              #     pathsToLink = [ "/demos" ];
              #   })
              # ];

              config = {
                Cmd = [ "hello" ];
                WorkingDir = "/mpyc/";
                Entrypoint = [ "/bin/bash" "-c" ];
                # Entrypoint = [ "/bin/bash" "-c" "cd /mpyc && $@" ];

                Env = [
                  "NIX_PAGER=cat"
                  # A user is required by nix
                  # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
                  "USER=somebody"
                ];
              };


              # runAsRoot = ''
              # '';


              # enableFakechroot = true;
              # fakeRootCommands = ''
              #   #!/bin/bash
              #   set -e

              #   mkdir /binzz
              #   ln -s ${pkgs.hello}/binzz/hello /binzz/hello
              #   whoami
              #   ls -al
              #   mkdir /tmp
              #   cd mpyc
              #   # echo ${pkgs.unixtools.ping}/bin/ping google.com
              #   # ${pkgs.curl}/bin/curl google.com
              #   # /nix/store/lcpnyijblclmjj58wgbs2fk7w100dciq-ping-iputils-20211215/bin/ping --help
              #   # /nix/store/lcpnyijblclmjj58wgbs2fk7w100dciq-ping-iputils-20211215/bin/ping google.com -c 3 -w 2
              #   # echo ${pkgs.unixtools.ping}/bin/ping google.com -c 3 -w 2
              #   # ${pkgs.unixtools.ping}/bin/ping google.com
              #   ${pkgs.poetry}/bin/poetry install
              # '';
              # # fakeRootCommands = ''
              # #   #!${pkgs.runtimeShell}
              # #   ${pkgs.dockerTools.shadowSetup}
              # #   groupadd -r redis
              # #   useradd -r -g redis redis
              # #   mkdir /data
              # #   chown redis:redis /data
              # # '';
            };
        in
        {
          packages.docker = buildImage pkgs;
          packages.arm = buildImage armPkgs;

          devShells.default = pkgs.mkShell
            {
              shellHook = ''
                export PYTHONPATH=./
              '';

              buildInputs = [
                (pkgs.poetry2nix.mkPoetryEnv
                  {
                    python = pkgs.python3;
                    projectDir = ./.;

                    # editablePackageSources = {
                    #   # mpyc = if builtins.getEnv "PWD" == "" then ./. else builtins.getEnv "PWD";
                    #   mpyc = ./.;
                    # };

                    overrides = pkgs.poetry2nix.overrides.withDefaults (
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
                        gmpy2 = pkgs.python3Packages.gmpy2;
                        # gmpy2 = super.gmpy2.overrideAttrs (
                        #   old: {
                        #     buildInputs = old.buildInputs ++ [ pkgs.gmp.dev pkgs.mpfr.dev pkgs.libmpc ];
                        #   }
                        # );
                      }
                    );
                  })
                pkgs.poetry
                pkgs.python3Packages.pip
              ];
            };
        });
}
