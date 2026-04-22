{config, ...}: {
  sops.secrets = {
    "server/minecraft/cfKey" = {
    };
  };

  virtualisation.oci-containers.containers.minecraft-modded = {
    image = "itzg/minecraft-server:latest";
    ports = ["25565:25565"];

    environmentFiles = [config.sops.secrets."server/minecraft/cfKey".path];

    environment = {
      EULA = "TRUE";
      TYPE = "AUTO_CURSEFORGE";

      CF_SLUG = "aoc";

      MEMORY = "8G";
    };

    volumes = [
      "/persist/var/lib/minecraft-server:/data"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [25565];
    allowedUDPPorts = [25565];
  };
}
