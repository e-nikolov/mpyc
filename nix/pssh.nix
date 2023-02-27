pkgs:
pkgs.pssh.overrideAttrs (final: old: {
  version = "2.3.5-pre";
  src = pkgs.fetchFromGitHub {
    owner = "lilydjwg";
    repo = "pssh";
    rev = "13995275fb163cbfc4ed42c63de594930ed68678";
    hash = "sha256-IWpsIEkxAtSM7vr2pnlHU3SR4A3eAWvsLnULUXrzJTg=";
  };
})
