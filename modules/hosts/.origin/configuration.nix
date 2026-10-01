{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  users.users."t" = {
    isNormalUser = true;
    initialPassword = "t";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ];
    packages = with pkgs; [
      firefox
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    just
    vim
    nixfmt
    pciutils
    usbutils
    steamdeck-firmware
    jupiter-dock-updater-bin
  ];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  networking = {
    hostName = "deck";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  jovian.devices.steamdeck.enable = true;
  jovian.steam = {
    enable = true;
    autoStart = true;
    user = "t";
  };
  jovian.steamos.useSteamOSConfig = true;
  jovian.hardware.has.amd.gpu = true;
  jovian.steam.desktopSession = "cosmic";
  services.desktopManager.cosmic.enable = true;
  hardware.enableRedistributableFirmware = true;
  security.rtkit.enable = true;

  system.stateVersion = "25.11";
}
