{ pkgs, ... }:

let
  mpyc = pkgs.python3Packages.buildPythonPackage {
    name = "mpyc";
    buildInputs = with pkgs.python3Packages; [
      gmpy2
      numpy
      pandas
      setuptools
      requests
      pip
      virtualenvwrapper
      qrcode
      # (./nix/didcomm.nix { inherit pkgs; })
      # peerdid
    ];

    src = ./.;
  };

  # peerdid = pkgs.python3Packages.buildPythonPackage rec {
  #   pname = "peerdid";
  #   version = "0.4.0";

  #   src = pkgs.python3Packages.fetchPypi {
  #     inherit pname version;
  #     sha256 =
  #       "08fdd5ef7c96480ad11c12d472de21acd32359996f69a5259299b540feba4560";
  #   };

  # };
in pkgs.mkShell {
  buildInputs = [
    mpyc
    pkgs.python3Packages.gmpy2
    pkgs.python3Packages.numpy
    pkgs.python3Packages.pandas
    pkgs.python3Packages.setuptools
    pkgs.python3Packages.requests
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenvwrapper
    pkgs.python3Packages.qrcode
  ];

  shellHook = ''
    export PIP_PREFIX=$(pwd)/_build/pip_packages
    export PATH="$PIP_PREFIX/bin:$PATH"
    export SOURCE_DATE_EPOCH=315532800
    alias pip="PIP_PREFIX='$HOME/.pip_packages' \pip"
    export PYTHONPATH=${pkgs.python3}/${pkgs.python3.sitePackages}:$HOME/.pip_packages/lib/python3.10/site-packages
  '';

  postShellHook = ''
    # allow pip to install wheels
    unset SOURCE_DATE_EPOCH
    pip install peerdid==0.4.0
  '';
}
# pkgs.python3Packages.buildPythonPackage rec {
#   #   pname = "oceanwaves";
#   #   version = "1.0.0rc6";
#   #   src = ../../../../../../Source/oceanwaves-python;
#   #   doCheck = false;

#   #   propagatedBuildInputs = with pkgs.python3Packages;
#   #     [ docopt numpy scipy xarray
#   #       ipython
#   #       dask
#   #       matplotlib
#   #       netcdf4
#   #       pandas
#   #       python-language-server
#   #       joblib
#   #     ];

# { pkgs ? import <nixpkgs> { } }:
# with pkgs;
# let
#   my-python = python3;
#   python-with-my-packages = my-python.withPackages (p:
#     with p; [
#       gmpy2
#       numpy
#       pandas
#       setuptools
#       requests
#       pip
#       virtualenvwrapper
#       # mpyc
#       # other python packages you want
#     ]);
# in mkShell {
#   #   pkgs.python3Packages.buildPythonPackage rec {
#   #   pname = "oceanwaves";
#   #   version = "1.0.0rc6";
#   #   src = ../../../../../../Source/oceanwaves-python;
#   #   doCheck = false;

#   #   propagatedBuildInputs = with pkgs.python3Packages;
#   #     [ docopt numpy scipy xarray
#   #       ipython
#   #       dask
#   #       matplotlib
#   #       netcdf4
#   #       pandas
#   #       python-language-server
#   #       joblib
#   #     ];
#   # }
#   buildInputs = [ python-with-my-packages ];

#   shellHook = ''
#     export PIP_PREFIX=$(pwd)/_build/pip_packages
#     export PATH="$PIP_PREFIX/bin:$PATH"
#     export SOURCE_DATE_EPOCH=315532800
#     alias pip="PIP_PREFIX='$HOME/.pip_packages' \pip"
#     export PYTHONPATH=${python-with-my-packages}/${python-with-my-packages.sitePackages}:$HOME/.pip_packages/lib/python3.10/site-packages
#   '';

#   postShellHook = ''
#     # allow pip to install wheels
#     unset SOURCE_DATE_EPOCH
#     pip install -e .
#   '';
# }
