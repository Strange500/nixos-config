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
      deadnix
      # Java
      maven
      gradle
      # Python
      python3
      python3Packages.virtualenv
      python3Packages.pip
      # JS/TS
      nodejs
      yarn
      pnpm
    ]
    ++ lib.optionals config.qgroget.nixos.apps.dev.jetbrains.enable [
      (jetbrains.plugins.addPlugins jetbrains.webstorm pluginListWeb)
      (jetbrains.plugins.addPlugins jetbrains.idea-ultimate pluginListInte)
    ]);

  home.sessionVariables = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    EDITOR = "code --wait --skip-welcome --skip-release-notes --disable-telemetry --skip-add-to-recently-opened";
    VISUAL = "code --wait --skip-welcome --skip-release-notes --disable-telemetry --skip-add-to-recently-opened";
    BROWSER = "firefox";
    TERMINAL = "kitty";
    FILE_MANAGER = "thunar";
  };
  programs = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    starship.enable = true;

    vscode = {
      enable = true;
      package = pkgs.vscode;
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
          mechatroner.rainbow-csv
          bradlc.vscode-tailwindcss
          ms-azuretools.vscode-docker
          ms-vscode.cpptools-extension-pack
          ms-vscode-remote.remote-ssh

          # nix
          jnoortheen.nix-ide
          # java
          redhat.java
          vscjava.vscode-gradle
          vscjava.vscode-maven
          vscjava.vscode-java-pack
          vscjava.vscode-java-debug
          vscjava.vscode-java-test
          vscjava.vscode-java-dependency
          # python
          ms-python.python
          ms-python.vscode-pylance
          ms-toolsai.jupyter
          # js
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
        ];
        userSettings = {
          "files.autoSave" = "afterDelay";
          "remote.SSH.configFile" = "/home/${config.qgroget.user.username}/.ssh/config";
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
          "java.gradle.buildServer.enabled" = "off";
        };
      };
    };
  };
}
