{
  pkgs,
  lib,
  ...
}: {
  vim = {
    extraPlugins = {
      blink-cmp-copilot = {
        package = pkgs.vimPlugins.blink-cmp-copilot;
      };
    };

    # 2. Configure Blink to use the manually installed plugin
    autocomplete.blink-cmp = {
      enable = true;
      setupOpts = {
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
            "copilot"
          ];
          providers = {
            copilot = {
              name = "copilot";
              module = "blink-cmp-copilot";
              score_offset = 100;
              async = true;
            };
          };
        };
      };
    };

    globals.rustaceanvim = {
      server = {
        default_settings = {
          # rust-analyzer language server configuration
          "rust-analyzer" = {
            checkOnSave = {
              command = "clippy";
            };
            cargo = {
              allFeatures = true;
            };
            procMacro = {
              enable = true;
            };
            inlayHints = {
              bindingModeHints = {
                enable = true;
              };
              closureReturnTypeHints = {
                enable = "always";
              };
              parameterHints = {
                enable = true;
              };
              typeHints = {
                enable = true;
              };
            };
          };
        };
      };
    };

    languages = {
      enableLSP = true;
      enableTreesitter = true;
      nix.enable = true;

      rust = {
        enable = true;
        # Do NOT use lsp.opts here. We handled it in globals above.
        crates.enable = true;
      };
    };

    # 2. FIXED: Copilot + Blink Integration
    assistant.copilot = {
      enable = true;
      #suggestion.enable = false; # Disable default ghost text to avoid conflict
      panel.enable = false;
    };

    options = {
      clipboard = "unnamedplus";
    };
    theme = {
      enable = true;
      name = "tokyonight"; # Modern VS Code-like aesthetic
      style = "night";
    };
    statusline.lualine.enable = true;
    telescope.enable = true;
    #  autocomplete.nvim-cmp.enable = true;
    binds.whichKey.enable = true;
    filetree.neo-tree.enable = true;
    # 4. Enable Debugging globally
    debugger.nvim-dap = {
      enable = true;
      ui.enable = true; # Adds a nice UI for debugging
    };
    git = {
      enable = true;
      gitsigns.enable = true;
    };
    # 5. Enable Autocompletion (blink-cmp is recommended for nvf)
    lsp.formatOnSave = true;
    utility.surround.enable = true; # Essential for editing tags/quotes
    ui.noice.enable = true; # Modern popups for commands/messages
    keymaps = [
      # Optional: Enable automatic formatting on save

      # Normal Mode
      {
        mode = "n";
        key = "<Up>";
        action = "<nop>";
      }
      {
        mode = "n";
        key = "<Down>";
        action = "<nop>";
      }
      {
        mode = "n";
        key = "<Left>";
        action = "<nop>";
      }
      {
        mode = "n";
        key = "<Right>";
        action = "<nop>";
      }

      # Insert Mode (prevents cheating while typing)
      {
        mode = "i";
        key = "<Up>";
        action = "<nop>";
      }
      {
        mode = "i";
        key = "<Down>";
        action = "<nop>";
      }
      {
        mode = "i";
        key = "<Left>";
        action = "<nop>";
      }
      {
        mode = "i";
        key = "<Right>";
        action = "<nop>";
      }

      # Visual Mode
      {
        mode = "v";
        key = "<Up>";
        action = "<nop>";
      }
      {
        mode = "v";
        key = "<Down>";
        action = "<nop>";
      }
      {
        mode = "v";
        key = "<Left>";
        action = "<nop>";
      }
      {
        mode = "v";
        key = "<Right>";
        action = "<nop>";
      }
    ];
  };
}
