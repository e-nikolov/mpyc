{ pkgs, ... }: {
  shellHook = ''
    export PYTHONPATH=./
  '';

  nativeBuildInputs = with pkgs; [
    poetry
    python3Packages.pip
    curl
    jq
    colmena
    pssh
    (terraform.withPlugins
      (tp: [
        tp.digitalocean
        tp.null
        tp.external
        tp.tailscale
        tp.random
      ]))

    mpyc-demo
  ];
}
