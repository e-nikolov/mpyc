{ pkgs, mach-nix, ... }:

let
  aa = builtins.traceVal mach-nix;
  bb = builtins.traceVal pkgs;

in let

  pythonPkgsWithMach =
    mach-nix.mkPythonShell { # replace with mkPythonShell if shell is wanted
      requirements = builtins.readFile ./requirements.txt;
    };
in pkgs.python3Packages.buildPythonPackage {
  name = "mpyc";
  buildInputs = with pkgs.python3Packages;
    [ pip setuptools virtualenvwrapper ] ++ [ pythonPkgsWithMach ];

  src = ./.;
}
