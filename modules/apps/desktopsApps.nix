{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.qgroget.nixos.apps.basic (import ./basics.nix {
      inherit config lib pkgs inputs;
    }))
    (lib.mkIf config.qgroget.nixos.apps.basic (import ./firefox/firefox.nix {
      inherit config lib pkgs inputs;
    }))
    (lib.mkIf config.qgroget.nixos.apps.basic (import ./kitty/kitty.nix {
      inherit config lib pkgs inputs;
    }))
    (lib.mkIf config.qgroget.nixos.apps.basic (import ./oh-my-zsh/oh-my-zsh.nix {
      inherit config lib pkgs inputs;
    }))
    (lib.mkIf config.qgroget.nixos.apps.sync (import ./syncthing/syncthing.nix {
      inherit config lib pkgs inputs;
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
