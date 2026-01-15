{
  pkgs,
  lib,
  ...
}: {
  # Import the split modules
  imports = [
    ./languages/rust.nix
    ./modules/autocomplete.nix
    ./modules/keymaps.nix
    ./modules/terminal.nix
  ];

  config.vim = {
    autopairs.nvim-autopairs = {
      enable = true;
      # Optional: setupOpts.disable_filetype = [ "TelescopePrompt" ];
    };
    options = {
      # Standard Rust/Modern coding settings
      tabstop = 4; # Width of a hard tab character
      shiftwidth = 4; # Width of an indentation level
      expandtab = true; # Convert tabs to spaces (Essential for Rust)
      smartindent = true; # smarter indentation for C-like languages

      # Optional: helps keep cursor in the middle of screen
      scrolloff = 8;
    };
    # --- General Language Settings ---
    languages = {
      enableLSP = true;
      enableTreesitter = true;
      # Simple languages can stay here, complex ones go to ./languages/
      nix.enable = true;
    };

    # --- UI & Theme ---
    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
    };

    ui.noice.enable = true; # Modern popups
    statusline.lualine.enable = true;
    filetree.neo-tree.enable = true;

    # --- Core Options ---
    options = {
      clipboard = "unnamedplus";
    };

    # --- Tools & Utils ---
    telescope.enable = true;
    binds.whichKey.enable = true;
    utility.surround.enable = true;
    lsp.formatOnSave = true;

    # --- Git ---
    git = {
      enable = true;
      gitsigns.enable = true;
    };

    # --- Debugging ---
    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
    };
  };
}
