{ pkgs, modulesPath, lib, name, ... }: {
  imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  environment.systemPackages = [
    pkgs.hello
    pkgs.arion
    pkgs.cowsay

    pkgs.docker-client
  ];

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.dnsname.enable = true;

  # Use your username instead of `myuser`
  users.extraUsers.root.extraGroups = [ "podman" ];

}
