{ inputs, pkgs, config, ... }:

{

      imports = [
      ];

      nixpkgs.config.pulseaudio = true;


      systemd.user.services.mpris-proxy = { # allow heaset button to control
            description = "Mpris proxy";
            after = [ "network.target" "sound.target" ];
            wantedBy = [ "default.target" ];
            serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
          };

          # audio
      hardware.pulseaudio = {
          enable = false;
          package = pkgs.pulseaudioFull;
          support32Bit = true;
          extraConfig = "load-module module-combine-sink; unload-module module-suspend-on-idle;";
      };






}

