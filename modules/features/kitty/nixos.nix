{
  modules.nixos.null.desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.vj.terminal];
  };
}
