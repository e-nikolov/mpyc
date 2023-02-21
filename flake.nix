{
  description = "MPyC flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/main";

    poetry2nix = {
      url = "github:nix-community/poetry2nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    { colmena = self.packages.x86_64-linux.colmena; }
    //
    flake-utils.lib.eachSystem (flake-utils.lib.defaultSystems ++ [ flake-utils.lib.system.armv7l-linux ])
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          mpyc-demo = (import ./nix/mpyc-demo.nix { inherit pkgs; dir = ./.; });

          headscale = (pkgs.headscale.overrideAttrs (final: old: {
            version = "v0.20.0";
            src = pkgs.fetchFromGitHub {
              owner = "juanfont";
              repo = "headscale";
              rev = "v0.20.0";
              hash = "sha256-RqJrqY1Eh5/TY+vMAO5fABmeV5aSzcLD4fX7j1QDN6w=";
            };
          }));

          mkDockerImage = import ./nix/docker.nix;
          shell = import ./nix/shell.nix { inherit pkgs; };

          mkImageConfig = import ./nix/image.nix;

          digitalOceanNodeConfig = mkImageConfig {
            inherit pkgs;
            imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
            extraPackages = [ mpyc-demo ];
          };

          digitalOceanHeadscaleConfig = mkImageConfig
            {
              inherit pkgs;
              imports = [ "${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix" ];
              extraPackages = [
                mpyc-demo
                pkgs.cowsay
                pkgs.lsof
                pkgs.fzf
                headscale
                pkgs.htop
              ];
              extraServices = {
                headscale.package = headscale;
                headscale.enable = true;
                headscale.settings = {
                  metrics_listen_addr = "127.0.0.1:9090";
                  listen_addr = "0.0.0.0:8080";
                  log = {
                    level = "debug";
                  };
                  ip_prefixes = [
                    "100.64.0.0/10"
                  ];
                  dns_config = {
                    override_local_dns = true;
                    # domains = [ "headnet.ts" ];
                    base_domain = "headnet.ts";
                  };
                };
              };
            };

          raspberryPi2Config = { config, ... }: mkImageConfig
            {
              inherit pkgs;
              imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix" ];
              extraPackages = [ mpyc-demo ];
            } // {
            boot.kernelPackages = pkgs.lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
          };

          raspberryPi4Config = { config, ... }: mkImageConfig
            {
              inherit pkgs;
              imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix" ];
              extraPackages = [ mpyc-demo ];
            };
        in
        {
          devShells.default = pkgs.mkShell {
            shellHook = ''
              export PYTHONPATH=./
            '';

            propagatedNativeBuildInputs = with pkgs; [
              mpyc-demo
              poetry
              python3Packages.pip
              curl
              jq

              colmena
              (pssh.overrideAttrs (final: old: {
                version = "2.3.5-pre";
                src = fetchFromGitHub {
                  owner = "lilydjwg";
                  repo = "pssh";
                  rev = "13995275fb163cbfc4ed42c63de594930ed68678";
                  hash = "sha256-IWpsIEkxAtSM7vr2pnlHU3SR4A3eAWvsLnULUXrzJTg=";
                };
              }))

              (terraform.withPlugins
                (tp: [
                  # (tp.digitalocean.overrideAttrs (final: old: {
                  #   rev = "a88a19be189e01aec9a9152dc3543f9a6493cc80";
                  #   hash = "123";
                  #   vendorHash = "123";
                  # }))
                  tp.null
                  tp.external
                  tp.tailscale
                  tp.random
                  (tp.mkProvider {
                    hash = "sha256-ZRMVmaNXQhJmo+pHjnkL0hk6pqYIblNrPfQe7mFg1f0=";
                    owner = "digitalocean";
                    repo = "terraform-provider-digitalocean";
                    rev = "a88a19be189e01aec9a9152dc3543f9a6493cc81";
                    version = "2.28.1";
                    homepage = "https://registry.terraform.io/providers/digitalocean/digitalocean";
                    vendorHash = null;
                  })
                  (tp.mkProvider {
                    hash = "sha256-8wnmdIRAnUgJx3uGpopyk3Ayi6NVJ5f8vB+DvHXfBBI=";
                    owner = "loafoe";
                    repo = "terraform-provider-ssh";
                    rev = "v2.4.0";
                    homepage = "https://registry.terraform.io/providers/loafoe/ssh/";
                    vendorHash = "sha256-MFp6KD9xXB6+B9XenGxxlR9Tueu4gDNeF1sMRvpIxGc=";
                  })
                ]))
            ];
          };

          packages.colmena =
            {
              meta = {
                nixpkgs = pkgs;
              };
              defaults = digitalOceanNodeConfig;
            } // builtins.fromJSON
              (builtins.readFile ./hosts.json)
            // builtins.mapAttrs
              (name: value: digitalOceanHeadscaleConfig)
              (builtins.fromJSON (builtins.readFile ./hosts-headscale.json));

          packages.digitalOceanImage = (pkgs.nixos (digitalOceanNodeConfig)).digitalOceanImage;
          packages.digitalOceanHeadscaleImage = (pkgs.nixos (digitalOceanHeadscaleConfig)).digitalOceanImage;

          packages.raspberryPi2Image = (pkgs.nixos (raspberryPi2Config)).sdImage;

          packages.raspberryPi4Image = (pkgs.nixos (raspberryPi4Config)).sdImage;
        });

}
