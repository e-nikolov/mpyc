{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = [
    python3
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.virtualenvwrapper
  ];

  shellHook = ''
    export SOURCE_DATE_EPOCH=315532800
    alias pip="PIP_PREFIX='$HOME/.pip_packages' \pip"
    export PYTHONPATH="$HOME/.pip_packages/lib/python3.7/site-packages:$PYTHONPATH"
  '';
}
