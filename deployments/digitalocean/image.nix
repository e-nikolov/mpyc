{ pkgs, lib, modulesPath, extraPackages ? [ ], ... }:
{
  imports = [ "${modulesPath}/virtualisation/digital-ocean-image.nix" ];
  # imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
  #   (modulesPath + "/virtualisation/digital-ocean-config.nix")
  # ];
  system.stateVersion = "22.11";

  environment.systemPackages = with pkgs; [
    hello
    arion
    cowsay

    docker-client
    jq
  ] ++ extraPackages;

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.dnsname.enable = true;
  networking.firewall = {
    # enable the firewall
    enable = true;
    checkReversePath = "loose";
    # # always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];

    # # allow the Tailscale UDP port through the firewall
    # allowedUDPPorts = [ 41643 3478 ];

    # # allow you to SSH in over the public internet
    # allowedTCPPorts = [ 22 443 ];
  };

  services.tailscale.enable = true;

  users.extraUsers.root.extraGroups = [ "podman" ];
}
