{
  description = "Build image";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
  outputs = { self, nixpkgs }: rec {
    # nixpkgs.overlays = [
    #   (self: super: {
    #     # Works around libselinux failure with python on armv7l.
    #     # LONG_BIT definition appears wrong for platform
    #     libselinux = (super.libselinux.override ({
    #       enablePython = false;
    #     })).overrideAttrs (_: {
    #       preInstall = ":";
    #     })
    #     ;
    #   })
    # ];

    nixosConfigurations.rpi2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
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
