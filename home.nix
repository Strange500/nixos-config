{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  # Voice dictation toggle agent (issue #48). Pure user-space: toggles a
  # background `pw-record`, then transcribes (whisper-cpp) and types the result
  # via `ydotool type` into the focused window. No root/sudo at runtime — the
  # ydotool daemon + uinput access are provisioned by modules/system/dictation.nix.
  dictationAgent = pkgs.writeShellApplication {
    name = "dictation";
    runtimeInputs = with pkgs; [
      whisper-cpp
      pipewire # pw-record
      ydotool
      libnotify # notify-send for user feedback
      coreutils # sed, tr, grep, sleep
    ];
    text = builtins.readFile ./home/scripts/dictation.sh;
  };
in {
  imports = [
    ./settings.nix
    ./hosts/setting.nix
    ./modules/desktop/hyprDesktop.nix
    ./modules/apps/desktopsApps.nix
    ./modules/shared
    ./home/modules/traefik-router.nix
    inputs.sops-nix.homeManagerModule
    inputs.dms.homeModules.dank-material-shell
  ];

  home = {
    username = "${config.qgroget.user.username}";
    homeDirectory = "/home/${config.qgroget.user.username}";
    sessionVariables = {
      GH_TOKEN = "$(cat ${config.sops.secrets."github_token".path})";
    };
    stateVersion = "25.11";
    packages = lib.mkIf (config.qgroget.nixos.isDesktop) (
      [
        pkgs.discord
        pkgs.moonlight-qt
        pkgs.nautilus
        pkgs.dejavu_fonts
        pkgs.nerd-fonts.jetbrains-mono
      ]
      ++ lib.optionals config.qgroget.nixos.dictation [dictationAgent]
    );
    file = {
      # Niri keybind for dictation. Always present (empty when disabled) so the
      # `include "dms/dictation.kdl"` in config.kdl never references a missing
      # file; generated (not static) so it can point at the toggle agent's
      # exact nix-store path. Mod+V is already the clipboard manager, so
      # dictation uses Mod+D.
      ".config/niri/dms/dictation.kdl" = {
        text =
          if config.qgroget.nixos.dictation
          then ''
            Mod+D hotkey-overlay-title="Dictée vocale" { spawn "${lib.getExe dictationAgent}"; }
          ''
          else "";
      };
      ".config" = {
        source = ./home/.config;
        recursive = true;
      };
      ".local" = {
        source = ./home/.local;
        recursive = true;
      };
      "wallpaper/${config.qgroget.nixos.theme}" = {
        source = ./home/wallpapers/${config.qgroget.nixos.theme};
        recursive = true;
      };
      ".ssh/config".text = "Host *\n          User ${config.qgroget.user.username}\n          IdentityFile '${
        config.sops.secrets."git/ssh/private".path
      }'\n          ";
    };
  };

  sops = {
    age.keyFile = "${config.qgroget.secretAgeKeyPath}";
    defaultSopsFile = ./secrets/secrets.yaml;

    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets = {
      "git/ssh/private" = {
        path = "${config.sops.defaultSymlinkPath}/git/ssh/private";
      };
      "github_token" = {};
    };
  };

  programs.gh = {
    enable = true;
    gitProtocol = "ssh";
  };

  programs.home-manager.enable = true;
}
