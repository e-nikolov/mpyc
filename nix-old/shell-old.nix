{ pkgs, ... }:

let
  peerdid = pkgs.python3Packages.buildPythonPackage rec {
    pname = "peerdid";
    version = "0.4.0";

    src = pkgs.python3Packages.fetchPypi {
      inherit version;
      inherit pname;
      sha256 = "sha256-CmHSbgjmVklal4CnJcaU9JvBEzjMzNFZj1Slg9Dpk1w=";
    };

    buildInputs = [ pkgs.python3Packages.base58 pkgs.python3Packages.varint ];
  };

  attrs = pkgs.python3Packages.buildPythonPackage rec {
    pname = "attrs";
    version = "21.2.0";

    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
      hash = "sha256-72qqw8ps2SkEzdDYP2KaFfGAU+yE5kMhBvek0Erk9fs=";
      # hash = "sha256-YmuoI0IR25joad92IwoTfExAoS1yRFxF1fW3FvB24v0=";
    };
    doCheck = false;
  };
  didcomm = pkgs.python3Packages.buildPythonPackage rec {
    pname = "didcomm";
    version = "0.3.0";

    src = pkgs.python3Packages.fetchPypi {
      inherit version;
      inherit pname;
      sha256 = "sha256-DevQrwxexy7l+p5K/wpxbzW1xEgSQewGt+o2I7i/59s=";
    };

    buildInputs = [
      pkgs.python3Packages.base58
      pkgs.python3Packages.packaging
      pkgs.python3Packages.varint
      pkgs.python3Packages.pycryptodomex
      pkgs.python3Packages.authlib
      attrs
    ];
  };

in pkgs.python3Packages.buildPythonPackage {
  name = "mpyc";
  buildInputs = with pkgs.python3Packages;
    [
      gmpy2
      numpy
      pandas
      setuptools
      requests
      pip
      virtualenvwrapper
      qrcode
      authlib
      base58
      varint
      packaging
    ] ++ [ peerdid didcomm attrs ];

  src = ./.;
}
