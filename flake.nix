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
    hyprpanel.url = "github:jas-singhfsu/hyprpanel";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {
    nixosConfigurations = {
        Clovis = nixpkgs.lib.nixosSystem {
          specialArgs = {
              inherit inputs;
              hostname = "Clovis";
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/Clovis/configuration.nix
            ./hardware-configuration.nix
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
            {nixpkgs.overlays = [inputs.hyprpanel.overlay];}
            disko.nixosModules.disko
          ];
        };

        Septimius = nixpkgs.lib.nixosSystem {
          specialArgs = {
              inherit inputs;
              hostname = "Septimius";
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/Septimius/configuration.nix
            ./hardware-configuration.nix
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
            {nixpkgs.overlays = [inputs.hyprpanel.overlay];}
            disko.nixosModules.disko
          ];
        };

        installer = nixpkgs.lib.nixosSystem {
          specialArgs = {
              inherit inputs;
              hostname = "installer";
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/installer/configuration.nix
            inputs.home-manager.nixosModules.default
            inputs.stylix.nixosModules.stylix
            {nixpkgs.overlays = [inputs.hyprpanel.overlay];}
          ];
        };

    };
  };
}
