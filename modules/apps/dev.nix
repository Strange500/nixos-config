{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  pluginListInte = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".idea-ultimate."2025.2"."com.github.copilot"
  ];
  pluginListWeb = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".webstorm."2025.2"."com.github.copilot"
  ];
  pluginListRust = [
    inputs.nix-jetbrains-plugins.plugins."${pkgs.system}".rust-rover."2025.2"."com.github.copilot"
  ];

  # Custom VSCode extension: Dynamic Base16 DankShell theme
  dynamic-base16-dankshell = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "dynamic-base16-dankshell";
      publisher = "dankshell";
      version = "1.0.0";
    };
    vsix = pkgs.fetchurl {
      url = "https://github.com/AvengeMedia/DankMaterialShell/raw/master/quickshell/matugen/dms-theme.vsix";
      sha256 = "01i92ryr2s9v6bpbpf9q7x2sajm7apik4s6g6wzhigxa13bp339h";
    };
  };
in {
  home.packages = lib.mkIf config.qgroget.nixos.apps.dev.enable (
    with pkgs;
      [
        devbox
        devenv
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
        (jetbrains.plugins.addPlugins jetbrains.rust-rover pluginListRust)
      ]
  );

  home.sessionVariables = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    EDITOR = "vim";
    VISUAL = "code --wait --skip-welcome --skip-release-notes --disable-telemetry --skip-add-to-recently-opened";
    BROWSER = "firefox";
    TERMINAL = "kitty";
    FILE_MANAGER = "thunar";
  };
  programs = lib.mkIf config.qgroget.nixos.apps.dev.enable {
    starship.enable = true;
    tmux.enable = true;
    vscode = {
      enable = true;
      package = pkgs.vscode;
      profiles.default = {
        enableExtensionUpdateCheck = true;
        enableUpdateCheck = true;
        extensions = with pkgs.vscode-extensions;
          [
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
          ]
          ++ [
            dynamic-base16-dankshell
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
          "workbench.colorTheme" = "Dynamic Base16 DankShell";
        };
      };
    };
  };
}
