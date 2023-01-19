{ pkgs, extraPackages ? [ ], imports ? [ ], ... }:
{
  inherit imports;
  system.stateVersion = "22.11";

  environment.systemPackages = with pkgs; [
    jq
  ] ++ extraPackages;

  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
  };
}
