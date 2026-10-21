{
  pkgs,
  lib,
  config,
  ...
}: let
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

  # Custom VSCode extension: ACP Client (Agent Client Protocol) by formulahendry.
  # Lets VS Code talk to any ACP-compatible agent over stdio (JSON-RPC), e.g.
  # Hermes Agent. Not yet in nixpkgs, so we pull the VSIX from Open VSX.
  acp-client-extension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "acp-client";
      publisher = "formulahendry";
      version = "0.2.0";
    };
    vsix = pkgs.fetchurl {
      url = "https://open-vsx.org/api/formulahendry/acp-client/0.2.0/file/formulahendry.acp-client-0.2.0.vsix";
      sha256 = "aef8eabe9d311e07c8a34eaaa8c2a965ddb8d06a00f09d651fab54557de55139";
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
        jdk
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
        gcc

        # LaTeX
        texliveFull
        texlab

        # Flutter
        flutter
        android-studio

        antigravity-cli
      ]
      ++ lib.optionals config.qgroget.nixos.apps.dev.rust.enable [
        # Rust: rustc/cargo (and their clippy/rustfmt components) come from the
        # rust-overlay toolchain (my-rust), so only the tools cargo does not
        # ship are added here. rust-analyzer is installed so VS Code uses the
        # Nix-built server instead of the glibc binary the extension downloads.
        rust-analyzer
        lldb
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
    tmux = {
      enable = true;
      clock24 = true;
      mouse = true;
      keyMode = "vi";
      prefix = "C-a";
      baseIndex = 1;
      escapeTime = 0;

      plugins = with pkgs.tmuxPlugins; [
        sensible
        vim-tmux-navigator
        catppuccin
        yank
        resurrect
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5'
          '';
        }
      ];

      extraConfig = ''
        # Better split shortcuts
        bind-key | split-window -h -c "#{pane_current_path}"
        bind-key - split-window -v -c "#{pane_current_path}"

        # Catppuccin configuration
        set -g @catppuccin_flavor 'mocha' # latte, frappe, macchiato or mocha
        set -g @catppuccin_window_status_style "rounded"

        # Renumber windows when one is closed
        set -g renumber-windows on

        # Improve colors
        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",xterm-256color:RGB"
      '';
    };
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
            oracle.oracle-java
            vscjava.vscode-gradle
            vscjava.vscode-maven
            vscjava.vscode-java-pack
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-java-dependency
            # python
            # ms-python.python
            # ms-python.vscode-pylance
            # ms-toolsai.jupyter
            # js
            dbaeumer.vscode-eslint
            esbenp.prettier-vscode
            # latex
            james-yu.latex-workshop
          ]
          ++ lib.optionals config.qgroget.nixos.apps.dev.rust.enable [
            # rust
            rust-lang.rust-analyzer
            vadimcn.vscode-lldb
            tamasfe.even-better-toml
            fill-labs.dependi
          ]
          ++ [
            dynamic-base16-dankshell
          ]
          ++ lib.optionals config.qgroget.nixos.apps.dev.acp.enable [
            acp-client-extension
          ];
        userSettings =
          {
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
            "latex-workshop.latex.autoBuild.run" = "onSave";
            "latex-workshop.latex.recipes" = [
              {
                "name" = "latexmk (pdf)";
                "tools" = ["latexmk"];
              }
            ];
            "latex-workshop.latex.tools" = [
              {
                "name" = "latexmk";
                "command" = "latexmk";
                "args" = [
                  "-synctex=1"
                  "-interaction=nonstopmode"
                  "-file-line-error"
                  "-pdf"
                  "%DOC%"
                ];
              }
            ];
            "workbench.colorTheme" = "Dynamic Base16 DankShell";
            "http.systemCertificatesNode" = true;
            "editor.semanticHighlighting.enabled" = true;
          }
          // lib.optionalAttrs config.qgroget.nixos.apps.dev.rust.enable {
            # --- Rust ---
            # NixOS: the extension's bundled server is a glibc download that will
            # not run here, so point rust-analyzer at the Nix-built binary.
            "rust-analyzer.server.path" = "${pkgs.rust-analyzer}/bin/rust-analyzer";
            "rust-analyzer.check.command" = "clippy";
            "rust-analyzer.check.extraArgs" = ["--all-targets"];
            "rust-analyzer.cargo.allFeatures" = true;
            "rust-analyzer.cargo.buildScripts.enable" = true;
            "rust-analyzer.procMacro.enable" = true;
            "rust-analyzer.restartServerOnConfigChange" = true;
            "rust-analyzer.files.excludeDirs" = ["target" "**/target"];
            "rust-analyzer.imports.granularity.group" = "module";
            "rust-analyzer.completion.autoimport.enable" = true;
            "rust-analyzer.inlayHints.bindingModeHints.enable" = true;
            "rust-analyzer.inlayHints.chainingHints.enable" = true;
            "rust-analyzer.inlayHints.parameterHints.enable" = true;
            "rust-analyzer.inlayHints.closureReturnTypeHints.enable" = "always";
            "rust-analyzer.inlayHints.lifetimeElisionHints.enable" = "skip_trivial";
            "[rust]" = {
              "editor.defaultFormatter" = "rust-lang.rust-analyzer";
              "editor.formatOnSave" = true;
              "editor.rulers" = [100];
            };
            "[toml]" = {
              "editor.defaultFormatter" = "tamasfe.even-better-toml";
              "editor.formatOnSave" = true;
            };
          }
          // lib.optionalAttrs config.qgroget.nixos.apps.dev.acp.enable {
            # ACP Client: Hermes Agent reachable over SSH from anywhere (solution B).
            # Runs remotely: ssh <host> sudo podman exec -i hermes hermes acp
            "acp.agents" = {
              "Hermes Agent" = {
                command = "ssh";
                args = [
                  "-T"
                  config.qgroget.nixos.apps.dev.acp.sshHost
                  "sudo"
                  "podman"
                  "exec"
                  "-i"
                  "hermes"
                  "hermes"
                  "acp"
                ];
              };
            };
            "acp.autoApprovePermissions" = "manual";
          };
        # Ready-to-use cargo tasks (Ctrl+Shift+B = build, Ctrl+Shift+P > Run Task).
        userTasks = lib.mkIf config.qgroget.nixos.apps.dev.rust.enable {
          version = "2.0.0";
          tasks = [
            {
              type = "shell";
              label = "rust: cargo build";
              command = "cargo";
              args = ["build"];
              group = {
                kind = "build";
                isDefault = true;
              };
              presentation.reveal = "always";
            }
            {
              type = "shell";
              label = "rust: cargo run";
              command = "cargo";
              args = ["run"];
              presentation.reveal = "always";
            }
            {
              type = "shell";
              label = "rust: cargo test";
              command = "cargo";
              args = ["test"];
              group = {
                kind = "test";
                isDefault = true;
              };
              presentation.reveal = "always";
            }
            {
              type = "shell";
              label = "rust: cargo check";
              command = "cargo";
              args = ["check" "--all-targets"];
              presentation.reveal = "always";
            }
            {
              type = "shell";
              label = "rust: cargo clippy";
              command = "cargo";
              args = ["clippy" "--all-targets"];
              presentation.reveal = "always";
            }
            {
              type = "shell";
              label = "rust: cargo fmt";
              command = "cargo";
              args = ["fmt"];
            }
          ];
        };
      };
    };
  };
}
