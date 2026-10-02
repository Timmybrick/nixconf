{
  modules.nixos.null.base = {
    persistence.cache.directories = [
      ".local/share/fish"
      ".local/share/zoxide"
    ];
  };
}
