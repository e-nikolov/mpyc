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
  services.tailscale.enable = true;
  networking.firewall.checkReversePath = "loose";
  networking.firewall.enable = false;


  # Use your username instead of `myuser`
  users.extraUsers.root.extraGroups = [ "podman" ];
}
