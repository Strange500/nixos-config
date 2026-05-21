{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.qgroget.nixos.isDesktop) {
    nixpkgs.config.pulseaudio = true;

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    systemd.user.services.mpris-proxy = {
      # allow heaset button to control
      description = "Mpris proxy";
      after = ["network.target" "sound.target"];
      wantedBy = ["default.target"];
      serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };

    # audio
    services.pulseaudio.enable = false;
  };
}
