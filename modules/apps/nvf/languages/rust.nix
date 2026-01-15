{pkgs, ...}: {
  vim.languages.rust = {
    enable = true;
    crates.enable = true;
  };
  vim.keymaps = [
    {
      key = "<leader>rr";
      mode = "n";
      action = ":RustLsp runnables<CR>"; # Opens a menu to Run, Test, or Debug
      silent = true;
      desc = "Rust Runnables";
    }
  ];
  # Rustaceanvim specific configuration
  vim.globals.rustaceanvim = {
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
