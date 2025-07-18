{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-jetbrains-plugins = {
      url = "github:theCapypara/nix-jetbrains-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpanel = {
      url = "github:jas-singhfsu/hyprpanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprland/hyprlang";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    impermanence,
    nur,
    sops-nix,
    jovian-nixos,
    ...
  } @ inputs: {
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
          impermanence.nixosModules.impermanence
          inputs.home-manager.nixosModules.default
          inputs.stylix.nixosModules.stylix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nur.modules.nixos.default
          nur.legacyPackages."x86_64-linux".repos.iopq.modules.xraya
          ({pkgs, ...}: {
            environment.systemPackages = [pkgs.nur.repos.mic92.hello-nur];
          })
        ];
      };

      Server = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          hostname = "Server";
        };
        system = "x86_64-linux";
        modules = [
          ./hosts/Server/configuration.nix
          ./hardware-configuration.nix
          impermanence.nixosModules.impermanence
          inputs.home-manager.nixosModules.default
          inputs.stylix.nixosModules.stylix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nur.modules.nixos.default
          nur.legacyPackages."x86_64-linux".repos.iopq.modules.xraya
          ({pkgs, ...}: {
            environment.systemPackages = [pkgs.nur.repos.mic92.hello-nur];
          })
        ];
      };

      Cube = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          hostname = "Cube";
        };
        system = "x86_64-linux";
        modules = [
          ./hosts/Cube/configuration.nix
          ./hardware-configuration.nix
          #impermanence.nixosModules.impermanence
          inputs.home-manager.nixosModules.default
          inputs.stylix.nixosModules.stylix
          disko.nixosModules.disko
          jovian-nixos.nixosModules.default
          sops-nix.nixosModules.sops
          nur.modules.nixos.default
          nur.legacyPackages."x86_64-linux".repos.iopq.modules.xraya
          ({pkgs, ...}: {
            environment.systemPackages = [pkgs.nur.repos.mic92.hello-nur];
          })
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
          impermanence.nixosModules.impermanence
          inputs.home-manager.nixosModules.default
          inputs.stylix.nixosModules.stylix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nur.modules.nixos.default
          nur.legacyPackages."x86_64-linux".repos.iopq.modules.xraya
          ({pkgs, ...}: {
            environment.systemPackages = [pkgs.nur.repos.mic92.hello-nur];
          })
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
        ];
      };
    };
  };
}
