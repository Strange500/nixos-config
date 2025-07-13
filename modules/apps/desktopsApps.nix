{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}: {
  config = lib.mkMerge [
    (
      lib.mkIf config.qgroget.nixos.apps.basic (lib.mkMerge [
        (import ./basics.nix {inherit config lib pkgs inputs;})
        (import ./firefox/firefox.nix {inherit config lib pkgs inputs;})
        (import ./kitty/kitty.nix {inherit config lib pkgs inputs;})
        (import ./oh-my-zsh/oh-my-zsh.nix {inherit config lib pkgs inputs;})
      ])
    )
    (lib.mkIf (config.qgroget.nixos.apps.sync.desktop.enable || config.qgroget.nixos.apps.sync.game.enable)  (import ./syncthing/syncthing.nix {
      inherit config lib pkgs inputs hostname;
    }))
    (lib.mkIf config.qgroget.nixos.apps.dev.enable (import ./dev.nix {
      inherit config lib pkgs inputs;
    }))
    (lib.mkIf config.qgroget.nixos.apps.media (import ./media.nix {
      inherit config lib pkgs inputs;
    }))
    (lib.mkIf config.qgroget.nixos.apps.crypto (import ./crypto.nix {
      inherit config lib pkgs inputs;
    }))
  ];
}
