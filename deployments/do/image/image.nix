{ pkgs, inputs, ... }:
let config = {
  # imports = [ <nixpkgs/nixos/modules/virtualisation/digital-ocean-image.nix> ];
  imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
  system.stateVersion = "22.11";
};
in
(pkgs.nixos config).digitalOceanImage
