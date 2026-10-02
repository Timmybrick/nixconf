{
  inputs,
  self,
  ...
}:
{
  hosts.deck =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.modules.nixos.base
        self.modules.nixos.desktop
        self.modules.nixos.impermanence

        inputs.disko.nixosModules.disko
        inputs.chaotic.nixosModules.default
        inputs.chaotic.vendored.jovian.nixosModules.default
        self.diskoConfigurations.deck
      ];

      preferences.user.name = "t";

      networking = {
        hostName = "deck";
        networkmanager.enable = true;
        firewall.enable = true;
      };

      programs.mango.enable = lib.mkForce false;

      jovian.devices.steamdeck.enable = true;
      jovian.steam = {
        enable = true;
        autoStart = true;
        user = "t";
        desktopSession = "cosmic";
      };
      jovian.steamos.useSteamOSConfig = true;
      jovian.hardware.has.amd.gpu = true;

      services.desktopManager.cosmic.enable = true;
      security.rtkit.enable = true;
      hardware.enableRedistributableFirmware = true;

      environment.systemPackages = with pkgs; [
        fcitx5
        qt6Packages.fcitx5-configtool
        fcitx5-gtk
        fcitx5-qt
        fcitx5-chewing
        nixfmt
        steamdeck-firmware
        jupiter-dock-updater-bin
      ];

      persistence.cache.directories = [ ".local/share/Steam" ];

      system.stateVersion = "25.11";
    };
}

# persistence = {
#   # 系统数据：持久化到 /persist/system
#   directories = [
#     "/var/lib/bluetooth"
#   ];
#   files = [
#     "/etc/example.conf"
#   ];

#   # 用户重要数据：持久化到 /persist/userdata 下的用户目录
#   data.directories = [
#     ".config/my-app"
#     ".local/share/my-app"
#   ];
#   data.files = [
#     ".config/my-app/settings.toml"
#   ];

#   # 用户缓存：单独持久化到 /persist/usercache
#   cache.directories = [
#     ".cache/my-app"
#   ];
# };
