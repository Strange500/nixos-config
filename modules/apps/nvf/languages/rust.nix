{pkgs, ...}: {
  vim = {
    # 1. Ensure global diagnostics are enabled (this IS an nvf option)
    diagnostics.enable = true;

    # 2. Configure the "Virtual Text" style using Lua
  };
  vim.debugger.nvim-dap = {
    enable = true;

    ui = {
      enable = true;
      autoStart = true; # Essential: Opens UI when you start debugging, closes when done
    };

    # 2. Optimized Mappings (Cleaner than defaults)
    # Assuming your Leader Key is Space
    mappings = {
      # Common actions need to be fast:
      toggleBreakpoint = "<leader>db"; # Add/Remove Breakpoint
      continue = "<leader>dc"; # Start/Continue (F5 equivalent)
      terminate = "<leader>dq"; # Stop debugging

      # Navigation (Stepping) - Simplified
      stepOver = "<leader>dn"; # "Next" line (F10)
      stepInto = "<leader>di"; # "Into" function (F11)
      stepOut = "<leader>do"; # "Out" of function (Shift+F11)

      # Navigation in the Stack
      goUp = "<leader>k"; # Go up stack trace (optional custom)
      goDown = "<leader>j"; # Go down stack trace

      # UI Toggles
      toggleDapUI = "<leader>du"; # Manually show/hide windows
      hover = "<leader>dh"; # Evaluate variable under cursor
    };
  };
  vim = {
    lsp.trouble.enable = true;

    # Add a keybind to toggle the error list
  };
  vim.extraPackages = [pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter];
  vim.languages.rust = {
    enable = true;
    crates.enable = true;
    dap.enable = true;
    dap.adapter = "codelldb";
  };
  vim.keymaps = [
    {
      key = "<leader>rr";
      mode = "n";
      action = ":RustLsp runnables<CR>"; # Opens a menu to Run, Test, or Debug
      silent = true;
      desc = "Rust Runnables";
    }
    {
      key = "<leader>du";
      mode = "n";
      action = ":lua require('dapui').toggle()<CR>";
      silent = true;
      desc = "Toggle Debugger UI";
    }

    {
      mode = "n";
      key = "<leader>xx";
      action = ":Trouble diagnostics toggle<CR>";
      desc = "Toggle Error List";
      silent = true;
    }
  ];

  vim.luaConfigPost = ''
      vim.diagnostic.config({
        virtual_text = true,   -- This is what puts the error text on the screen
        signs = true,          -- Shows the icon in the sidebar
        underline = true,      -- Underlines the error
        update_in_insert = false,
        severity_sort = true,
      })
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
        end
      end,
    })
  '';

  # Rustaceanvim specific configuration
  vim.globals.rustaceanvim = {
    dap = {
      adapter = {
        type = "server";
        port = "\${port}";
        executable = {
          # Point directly to the binary in the nix store
          command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
          args = [
            "--port"
            "\${port}"
          ];
        };
      };
    };
    server = {
      default_settings = {
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
}
