{
  description = "my project description";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.mach-nix = {
    url = "https://github.com/DavHau/mach-nix";
    # ref = "refs/tags/3.5.0";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in { devShells.default = import ./shell.nix { inherit pkgs; }; });
}
