{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";
    hyprland.url = "github:hyprwm/Hyprland";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.Clovis = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      system = "x86_64-linux";
      modules = [
        ./hosts/Clovis/configuration.nix
        inputs.home-manager.nixosModules.default
        inputs.stylix.nixosModules.stylix
      ];
    };

    nixosConfigurations.Septimius = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          system = "x86_64-linux";
          modules = [
            ./hosts/Septimius/configuration.nix
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
          ];
        };
  };
}
