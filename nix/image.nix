{ pkgs, extraPackages ? [ ], extraServices ? { }, imports ? [ ], ... }:
{
  inherit imports;
  system.stateVersion = "22.11";

  environment.systemPackages = with pkgs; [
    jq
    docker
    docker-compose
  ] ++ extraPackages;

  services = {
    tailscale.enable = true;
  } // extraServices;

  networking.firewall = {
    enable = false;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
  };

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  # virtualisation.podman.dockerCompat = true;
}
