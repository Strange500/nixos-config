{...}: {
  services.home-assistant = {
    enable = true;

    extraComponents = [
      # List of required components
      "default_config"
      "met"
      "radio_browser"
      "zha"
    ];

    extraPackages = ps:
      with ps; [
        zlib-ng
        zigpy
        bellows
      ];
    config = {
      http = {
        server_port = 8123; # still listen on 8123 internally
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1/32"
          "::1/128"
        ];
      };
      zha = {
        database_path = "/var/lib/hass/zigbee.db";
        enable_quirks = true;
      };
    };
  };

  users.users.hass.extraGroups = ["dialout"];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", \
      MODE="0666", GROUP="dialout", \
      SYMLINK+="zigbee"
  '';

  # tmpfiles to ensure /var/lib/hass exists
  systemd.tmpfiles.rules = [
    "d /var/lib/hass 0750 hass hass -"
  ];

  qgroget.services = {
    home-assistant = {
      name = "home-assistant";
      url = "http://localhost:8123";
      type = "public";
      unitName = "home-assistant.service";
      journalctl = true;
      persistedData = [
        "/var/lib/hass"
      ];
      backupDirectories = [
        "/var/lib/hass"
      ];
    };
  };
}
