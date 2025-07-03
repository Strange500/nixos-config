{ pkgs, inputs, ... }: {
  config = {
    settings = {
      monitors = [ "DP-1, 1920x1080, 0x0, 1" ];
      stylix = { theme = "atelier-cave"; };
    };
  };
}
