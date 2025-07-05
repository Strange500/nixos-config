{
  pkgs,
  inputs,
  ...
}: {
  config = {
    qgroget.nixos = {
      desktop = {
        monitors = ["DP-1, 1920x1080, 0x0, 1"];
      };
    };
  };
}
