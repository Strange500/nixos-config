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
      url = "github:nix-community/disko";
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
    };

    jovian-nixos.url = "github:Jovian-Experiments/Jovian-NixOS";
    jovian-nixos.inputs.nixpkgs.follows = "nixpkgs";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    portfolio = {
      url = "github:strange500/nextPortfolio";
    };
  };

  outputs = {
    nixpkgs,
    declarative-jellyfin,
    home-manager,
    stylix,
    disko,
    sops-nix,
    nur,
    chaotic,
    impermanence,
    quadlet-nix,
    portfolio,
    jovian-nixos,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    # Common modules used by most hosts
    commonModules = [
      home-manager.nixosModules.default
      stylix.nixosModules.stylix
      disko.nixosModules.disko
      sops-nix.nixosModules.sops
      chaotic.nixosModules.default
    ];

    # Desktop-specific modules
    desktopModules = [
      impermanence.nixosModules.impermanence
    ];

    # Server-specific modules
    serverModules = [
      impermanence.nixosModules.impermanence
      declarative-jellyfin.nixosModules.default
      quadlet-nix.nixosModules.quadlet
      portfolio.nixosModules.default
      # {
      #   nixpkgs.overlays = [
      #     (final: prev: {
      #       jellyfin =
      #         (import (builtins.fetchTarball {
      #           url = "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz";
      #           sha256 = "sha256:0bz1qwd1fw9v4hmxi6h2qfgvxpv4kwdiz7xd9p7j1msr0b8d54h3";
      #         }) {inherit system;}).jellyfin;
      #     })
      #   ];
      # }
    ];

    # Gaming-specific modules (for Steam Deck-like devices)
    gamingModules = [
      jovian-nixos.nixosModules.default
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
    checks.${system} = let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      jellyfinTest = import ./tests/jellyfin {
        inherit pkgs;
        inherit declarative-jellyfin;
      };
      jellyseerrTest = import ./tests/jellyseerr {
        inherit pkgs;
      };
    };
    nixosConfigurations = {
      # Desktop workstation
      Clovis = mkSystem "Clovis" desktopModules;

      # Server configuration
      Server = mkSystem "Server" serverModules;

      # Gaming device (Steam Deck-like)
      Cube = mkSystem "Cube" gamingModules;

      # Another desktop/workstation
      Septimius = mkSystem "Septimius" desktopModules;

      Clotaire = mkSystem "Clotaire" desktopModules;

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

    # pi with system in arm
    nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = {
        inherit inputs;
        hostname = "pi";
      };

      modules =
        [
          ./hosts/pi/configuration.nix
        ]
        ++ commonModules;
    };
  };
}
