{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {

    # { modulesPath, lib, name, ... }: {
    #     imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
    #       (modulesPath + "/virtualisation/digital-ocean-config.nix")
    #     ];

    #   };

    nixosConfigurations.doHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # add things here
      ];
    };
  };
}
