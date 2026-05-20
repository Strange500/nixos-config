{
  config,
  lib,
  ...
}: {
  # This module configures the eduroam network declaratively using NetworkManager.
  # It expects secrets to be provided via sops.

  sops.secrets."networking/eduroam/identity" = {};
  sops.secrets."networking/eduroam/password" = {};

  networking.networkmanager.ensureProfiles.profiles = {
    eduroam = {
      connection = {
        id = "eduroam";
        type = "wifi";
        # Only try to connect when the interface is wlp1s0 (typical for this laptop)
        interface-name = "wlp1s0";
      };
      wifi = {
        ssid = "eduroam";
        mode = "infrastructure";
      };
      "wifi-security" = {
        key-mgmt = "wpa-eap";
      };
      "802-1x" = {
        eap = "peap;";
        identity = "@file:${config.sops.secrets."networking/eduroam/identity".path}";
        password = "@file:${config.sops.secrets."networking/eduroam/password".path}";
        "phase2-auth" = "mschapv2";
        "system-ca-certs" = false;
      };
    };
  };
}
