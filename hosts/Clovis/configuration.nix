{ pkgs, inputs, ... }:

    {
    imports =
    [
      ../global.nix
      ../../modules/config.nix
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";

     ## put age key here
    sops.age.keyFile = "/home/strange/.config/sops/age/keys.txt";

    sops.secrets."git/ssh/private" = {
      owner = "strange";
    };

    sops.secrets."wireguard/conf" = {
          owner = "strange";
    };

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/nvme0n1";
    boot.loader.grub.useOSProber = true;

    boot.kernelParams = [ "acpi_enforce_resources=lax" ];

    networking.hostName = "Clovis";
}

