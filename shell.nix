with import <nixpkgs> { };

python3Packages.buildPythonPackage {
  name = "mpyc";
  buildInputs = with python3Packages; [
    gmpy2
    numpy
    pandas
    setuptools
    requests
    pip
    virtualenvwrapper
    qrcode
    mach-nix.mkPython
    {
      requirements = ''
        pillow
        numpy
        requests
      '';
    }
    ./nix/didcomm.nix
    peerdid
  ];

  src = ./.;
}

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
