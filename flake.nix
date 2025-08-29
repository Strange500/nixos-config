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
    };

    declarative-jellyfin = {
      url = "github:Sveske-Juice/declarative-jellyfin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crowdsec = {
      url = "git+https://codeberg.org/kampka/nix-flake-crowdsec.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    portfolio = {
      url = "github:strange500/nextPortfolio";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";

    # Common modules used by most hosts
    commonModules = [
      inputs.home-manager.nixosModules.default
      inputs.stylix.nixosModules.stylix
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.nur.modules.nixos.default
      inputs.chaotic.nixosModules.default
      inputs.nur.legacyPackages.${system}.repos.iopq.modules.xraya
      ({pkgs, ...}: {
        environment.systemPackages = [pkgs.nur.repos.mic92.hello-nur];
      })
    ];

    # Desktop-specific modules
    desktopModules = [
      inputs.impermanence.nixosModules.impermanence
    ];

    # Server-specific modules
    serverModules = [
      inputs.impermanence.nixosModules.impermanence
      inputs.declarative-jellyfin.nixosModules.default
      inputs.quadlet-nix.nixosModules.quadlet
      inputs.crowdsec.nixosModules.crowdsec
      inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
      inputs.portfolio.nixosModules.default
    ];

    # Gaming-specific modules (for Steam Deck-like devices)
    gamingModules = [
      inputs.jovian-nixos.nixosModules.default
      inputs.nixpkgs-xr.nixosModules.nixpkgs-xr
    ];

    # Helper function to create a NixOS system configuration
    mkSystem = hostname: extraModules:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          hostname = hostname;
        };
        inherit system;
        modules =
          [
            ./hosts/${hostname}/configuration.nix
          ]
          ++ commonModules ++ extraModules;
      };
  in {
    nixosConfigurations = {
      # Desktop workstation
      Clovis = mkSystem "Clovis" desktopModules;

      # Server configuration
      Server = mkSystem "Server" serverModules;

      # Gaming device (Steam Deck-like)
      Cube = mkSystem "Cube" gamingModules;

      # Another desktop/workstation
      Septimius = mkSystem "Septimius" desktopModules;

      # Installer ISO
      installer = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          hostname = "installer";
        };
        inherit system;
        modules = [
          ./hosts/installer/configuration.nix
        ];
      };
    };
  };
}
