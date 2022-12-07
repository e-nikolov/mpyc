{ pkgs, lib, modulesPath, extraPackages ? [ ], ... }:
{
  imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
  system.stateVersion = "22.11";

  environment.systemPackages = [
    pkgs.jq
    mpyc-demo
  ];

  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
  };
}
