pkgs: dir:
(pkgs.poetry2nix.mkPoetryEnv
  {
    python = pkgs.python311;
    projectDir = dir;

    extraPackages = (ps: [
      (pkgs.python311Packages.buildPythonPackage
        {
          name = "mpyc";
          src = dir;
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

        gmpy2 = pkgs.python311Packages.gmpy2;
      }
    );
  })
