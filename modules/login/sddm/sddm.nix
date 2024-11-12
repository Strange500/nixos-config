{ inputs, pkgs, config, ... }:

{
    services.displayManager.sddm = {
            enable = true;
        #    wayland.enable = true;
            theme = "${import ./themes/sddm-theme.nix { inherit pkgs; }}";
            autoNumlock = true;
            package = pkgs.kdePackages.sddm;
            extraPackages = [
              pkgs.kdePackages.qt5compat
            ];
        };

}

