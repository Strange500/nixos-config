{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../global.nix
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.jovian-nixos.nixosModules.default
    ./hardware-configuration.nix
  ];

  # services.xserver.enable = true;

  # networking.interfaces.enp3s0.wakeOnLan.enable = true;
}
