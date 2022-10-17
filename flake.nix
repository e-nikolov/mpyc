{
  description = "my project description";

  inputs = {
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
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, pypi-deps-db }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonEnv = mach-nix.lib."${system}".mkPython {
          requirements = builtins.readFile ./requirements.txt;
        };
      in {
        devShell = pkgs.mkShell {

          buildInputs = [
            pythonEnv
            (pkgs.python3Packages.buildPythonPackage {
              name = "mpyc";

              # propagatedBuildInputs = with pkgs.python3Packages; [ pip ];
              src = ./.;
            })
          ];
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
