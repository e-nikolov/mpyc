{
  description = "Build image";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
  outputs = { self, nixpkgs }: rec {
    nixosConfigurations.rpi2 = nixpkgs.lib.nixosSystem {
      system = "armv7l-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix"
        {
          nixpkgs.config.allowUnsupportedSystem = true;
          nixpkgs.crossSystem.system = "armv7l-linux";
          imports = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ];

          # ... extra configs as above
        }
      ];
    };
    images.rpi2 = nixosConfigurations.rpi2.config.system.build.sdImage;
  };
}
