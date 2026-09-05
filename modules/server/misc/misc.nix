{pkgs, ...}: {
  # `misc` host user: rootless container sandbox for self-hosted services
  # (currently the portfolio). No SSH access. Its Home Manager config is declared
  # once in home/misc.nix and deployed BOTH by `nixos-rebuild switch` (via
  # home-manager.users.misc) AND manually with `home-manager switch --flake .#misc`
  # (via the homeConfigurations.misc output).
  users.users.misc = {
    isNormalUser = true;
    home = "/home/misc";
    shell = pkgs.zsh;
    description = "Misc rootless services";
    # Start rootless quadlets at boot without login.
    linger = true;
    # Dynamic subuid/subgid ranges for rootless multi-user podman.
    autoSubUidGidRange = true;
    extraGroups = [
      "podman" # rootless container runtime access
      "nix-users" # Nix daemon access for `home-manager switch`
      "traefik-users" # write /var/lib/traefik/dynamic/misc.toml
    ];
  };
}
