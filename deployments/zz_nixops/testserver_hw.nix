{
  resources.sshKeyPairs.ssh-key = {
    # publicKey = builtins.readFile ./tstKey.pub;
    # privateKey = builtins.readFile ./tstKey;
  };

  # Hardware config
  testserver = { config, pkgs, ... }: {
    deployment.targetEnv = "digitalOcean";
    deployment.digitalOcean.enableIpv6 = true;
    deployment.digitalOcean.region = "ams2";
    deployment.digitalOcean.size = "512mb";
    deployment.digitalOcean.image = "";
    # deployment.digitalOcean.authToken = "Doesn't seem to work";
  };
}
