{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  pluginListInte = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".idea-ultimate."2025.1"."com.github.copilot"
  ];
  pluginListWeb = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".webstorm."2025.1"."com.github.copilot"
  ];
in {
  home.packages = lib.mkIf config.qgroget.nixos.apps.dev.enable (with pkgs;
    [
      devbox
      libnotify
      pre-commit
      alejandra
      nixd
    ]
    ++ lib.optionals config.qgroget.nixos.apps.dev.jetbrains.enable [
      (jetbrains.plugins.addPlugins jetbrains.webstorm pluginListWeb)
      (jetbrains.plugins.addPlugins jetbrains.idea-ultimate pluginListInte)
    ]);

  home.sessionVariables = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    EDITOR = "lvim";
    VISUAL = "lvim";
    BROWSER = "firefox";
    TERMINAL = "kitty";
    FILE_MANAGER = "thunar";
  };
  programs = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    starship.enable = true;
    vscode = {
      enable = true;
      profiles.default = {
        enableExtensionUpdateCheck = true;
        enableUpdateCheck = true;
        extensions = with pkgs.vscode-extensions; [
          zainchen.json
          github.copilot
          github.copilot-chat
          ms-vscode.live-server
          oderwat.indent-rainbow
          esbenp.prettier-vscode
          dbaeumer.vscode-eslint
          codezombiech.gitignore
          yoavbls.pretty-ts-errors
          vscjava.vscode-java-pack
          mechatroner.rainbow-csv
          bradlc.vscode-tailwindcss
          ms-azuretools.vscode-docker
          ms-vscode.cpptools-extension-pack
          ms-vscode-remote.remote-ssh
        ];
        userSettings = {
          "files.autoSave" = "afterDelay";
          "remote.SSH.configFile" = "/home/strange/ssh-config";
          "github.copilot.enable" = {
            "*" = true;
            "plaintext" = true;
            "markdown" = true;
            "scminput" = false;
          };
          "nix.serverPath" = "nixd";
          "nix.enableLanguageServer" = true;
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = ["alejandra"];
              };
              "nixpkgs" = {
                "expr" = "import (builtins.getFlake \"${config.qgroget.nixos.settings.confDirectory}\").inputs.nixpkgs { }";
              };
              "options" = {
                "nixos" = {
                  "expr" = "(builtins.getFlake \"${config.qgroget.nixos.settings.confDirectory}\").nixosConfigurations.Clovis.options";
                };
                "home-manager" = {
                  "expr" = "(builtins.getFlake \"${config.qgroget.nixos.settings.confDirectory}\").nixosConfigurations.Clovis.options.home-manager.users.type.getSubOptions []";
                };
              };
            };
          };
        };
      };
    };
  };
}
