{
  description = "Steam Deck Jovian Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      chaotic,
      disko,
      ...
    }:
    let
      inherit (chaotic.vendored) jovian;
    in
    {
      nixosConfigurations = {
        steamdeck = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            jovian.nixosModules.default
            chaotic.nixosModules.default
            ./disko.nix
            ./configuration.nix
          ];
        };
      };
    };
}
