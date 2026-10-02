{
  modules.nixos.null.desktop = {
    services.tailscale.enable = true;
    services.tailscale.openFirewall = true;
    services.tailscale.extraSetFlags = ["--ssh"];

    persistence.directories = [
      "/var/lib/tailscale"
    ];
  };
}
