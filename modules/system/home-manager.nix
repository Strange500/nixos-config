{
  config,
  inputs,
  pkgs,
  hostname,
  ...
}: {
  home-manager.backupFileExtension = "backup";

  home-manager = {
    extraSpecialArgs = {
      inherit inputs pkgs hostname;
    };
    users."${config.qgroget.user.username}" = import ../../home.nix;
  };
}
