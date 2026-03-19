{config, ...}: {
  sops.secrets = {
    "server/minecraft/cfKey" = {
    };
  };

  virtualisation.oci-containers.containers.minecraft-modded = {
    image = "itzg/minecraft-server:latest";
    ports = ["25565:25565"];

    # # Securely load your API key from the file you created
    environmentFiles = [config.sops.secrets."server/minecraft/cfKey".path];

    environment = {
      EULA = "TRUE";
      TYPE = "AUTO_CURSEFORGE";

      # Identify the modpack using its "slug" (the part of the URL after /modpacks/)
      # For example: https://www.curseforge.com/minecraft/modpacks/all-the-mods-9
      CF_SLUG = "aoc";

      # IMPORTANT: Modpacks need memory!
      # The default is 1G, which will instantly crash a big CurseForge pack.
      MEMORY = "8G";
    };

    volumes = [
      # Mount a persistent directory on your host to store world data, configs, etc.
      "/persist/var/lib/minecraft-server:/data"
    ];
  };

  # 3. Open the firewall so players can join
  networking.firewall = {
    allowedTCPPorts = [25565];
    allowedUDPPorts = [25565];
  };
}
