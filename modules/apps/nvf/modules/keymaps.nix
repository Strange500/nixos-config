{...}: {
  vim.keymaps = [
    # General Utils
    {
      mode = "n";
      key = "<leader>e";
      action = ":Neotree reveal<CR>";
    }
    {
      mode = "n";
      key = "<leader>f";
      action = ":Neotree focus<CR>";
    }
    # --- Hard Mode (Disable Arrow Keys) ---
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

    # Insert Mode
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
}
