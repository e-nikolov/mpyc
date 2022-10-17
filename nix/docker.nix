{ pkgs ? import <nixpkgs> { }
, pkgsLinux ? import <nixpkgs> { system = "x86_64-linux"; } }:

# buildImage {
#   name = "hello-docker";
#   config = { Cmd = [ "${pkgsLinux.hello}/bin/hello" ]; };
# }

pkgs.dockerTools.buildImage {
  name = "enikolov/mpyc-demo";
  tag = "v0.0.1";

  fromImage = "python";
  fromImageName = null;
  fromImageTag = "3.10.7";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ pkgs.redis ];
    pathsToLink = [ "/bin" ];
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    mkdir -p /data
  '';

  config = {
    Cmd = [ "/bin/redis-server" ];
    WorkingDir = "/data";
    Volumes = { "/data" = { }; };
  };

  diskSize = 1024;
  buildVMMemorySize = 512;
}
