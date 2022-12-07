{ pkgs, ... }: {
  shellHook = ''
    export PYTHONPATH=./
  '';

  nativeBuildInputs = with pkgs; [
    mpyc-demo
    poetry
    python3Packages.pip
    curl

    (terraform.withPlugins
      (tp: [ tp.digitalocean tp.null tp.external tp.tailscale tp.random ]))
    jq
    colmena
    pssh
  ];
}
