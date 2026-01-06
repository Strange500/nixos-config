{
  pkgs,
  lib,
  ...
}: {
  vim = {
    assistant.copilot.cmp.enable = true;
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
    languages = {
      enableLSP = true;
      enableTreesitter = true;

      nix.enable = true;
      ts.enable = true;
      #rust.enable = true;
    };

    languages.rust = {
      enable = true; # Basic support (uses rustaceanvim)
      lsp.enable = true; # Connects rust-analyzer
      dap.enable = true; # Enables Debugging (requires debugger.nvim-dap.enable)
      crates.enable = true; # Integrates crates.nvim for Cargo.toml management
    };
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
    autocomplete.blink-cmp.enable = true;
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
