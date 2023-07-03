pkgs:
let
  user = "pi";
  password = "...";
  SSID = "...";
  SSIDpassword = "...";
  interface = "wlan0";
  hostname = "rpi1";
in
{
  imports = [ "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix" ];
  boot.kernelPackages = pkgs.lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;

  nixpkgs.system = "armv7l-linux";
  nix.settings.substituters = pkgs.lib.mkForce [ "https://cache.armv7l.xyz" ];
  nix.settings.trusted-public-keys = [ "cache.armv7l.xyz-1:kBY/eGnBAYiqYfg0fy0inWhshUo+pGFM3Pj7kIkmlBk=" ];

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  networking = {
    hostName = hostname;
    wireless = {
      enable = true;
      networks."${SSID}".psk = SSIDpassword;
      interfaces = [ interface ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];
  # virtualisation.docker.enable = true;
  # services.tailscale.enable = true;

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" "docker" ];
    };
  };

  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
