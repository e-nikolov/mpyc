{
  nixie = { modulesPath, lib, name, ... }: {
    imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
    ];

    deployment.targetHost = "198.51.100.207";
    deployment.targetUser = "root";

    networking.hostName = name;
  };
}
