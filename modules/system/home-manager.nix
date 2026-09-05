{
  config,
  inputs,
  pkgs,
  hostname,
  lib,
  ...
}: let
  # Base Home Manager config for the primary user (applies on every host).
  primaryUser = {
    "${config.qgroget.user.username}" = import ../../home.nix;
  };

  # Server-only rootless users. Their config lives ONCE in home/<user>.nix and is
  # re-used by the `homeConfigurations` flake outputs (`home-manager switch
  # --flake .#hermes` / `.#misc`). Registering them here as well means a
  # `nixos-rebuild switch` deploys them automatically together with the system,
  # while the manual `home-manager switch` path keeps working — both from the
  # exact same file, so the two never drift.
  serverUsers = lib.optionalAttrs (hostname == "Server") {
    hermes = import ../../home/hermes.nix;
    misc = import ../../home/misc.nix;
  };
in {
  home-manager = {
    # Build every user env against the global system `pkgs`, matching what the
    # `homeConfigurations` outputs use (`nixpkgs.legacyPackages.${system}`) so
    # the `nixos-rebuild switch` and `home-manager switch` paths agree.
    useGlobalPkgs = true;

    extraSpecialArgs = {
      inherit inputs pkgs hostname;
    };

    # Primary user (every host) + the server's rootless users (Server only).
    users = primaryUser // serverUsers;
  };

  home-manager.backupFileExtension = "backup";
}