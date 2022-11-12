{ pkgs, lib, modulesPath, extraPackages ? [ ], ... }:
{
  imports = [ "${modulesPath}/virtualisation/digital-ocean-image.nix" ];
  system.stateVersion = "22.11";

  environment.systemPackages = with pkgs; [
    hello
    arion
    cowsay

    docker-client
    jq
  ] ++ extraPackages;

  services.tailscale.enable = true;

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.dnsname.enable = true;

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];

    # allowedUDPPorts = [ 41643 3478 ];
    # allowedTCPPorts = [ 22 443 ];
  };

  users.extraUsers.root.extraGroups = [ "podman" ];
}
