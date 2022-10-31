pkgs: name: tag: pkgs.dockerTools.buildLayeredImage
{
  name = name;
  tag = tag;
  created = builtins.substring 0 8 self.lastModifiedDate;

  contents = pkgs.buildEnv
    {
      name = "zzz-python-env-123";
      paths = [
        (pkgs.poetry2nix.mkPoetryEnv
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
                # numpy = pkgs.python3Packages.numpy;
                # cryptography = pkgs.python3Packages.cryptography;
                # matplotlib = pkgs.python3Packages.matplotlib;
                # gmpy2 = super.gmpy2.overrideAttrs (
                #   old: {
                #     buildInputs = old.buildInputs ++ [ pkgs.gmp.dev pkgs.mpfr.dev pkgs.libmpc ];
                #   }
                # );
              }
            );
          })
        pkgs.poetry
        # pkgs.python3Packages.numpy
        # pkgs.python3Packages.matplotlib
        pkgs.python3Packages.pip
        # pkgs.hello
        pkgs.gnugrep
        # pkgs.python3
        pkgs.coreutils
        pkgs.bashInteractive
        pkgs.nix
        pkgs.which
        pkgs.curl
        pkgs.gnumake
        pkgs.zsh
        pkgs.fzf
        pkgs.fzf-zsh
        pkgs.gawk
        pkgs.unixtools.nettools
        pkgs.unixtools.ping
        pkgs.unixtools.top
        pkgs.wget
        pkgs.tailscale
        (pkgs.buildEnv {
          name = "mpyc-root";
          paths = [ ./. ];
          # pathsToLink = [ "/demos" ];
          extraPrefix = "/mpyc";
        })

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

  config = {
    Cmd = [ "demo" ];
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
} 
