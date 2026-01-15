{pkgs, ...}: {
  vim.terminal.toggleterm = {
    enable = true;

    # Keybinding to toggle the terminal
    mappings = {
      open = "<C-t>"; # Ctrl+t is a common choice, or use <F7>
    };

    # Visual settings
    direction = "float"; # Options: "horizontal", "vertical", "float"

    # Optional: Integration with LazyGit
    lazygit = {
      enable = true;
      # This enables :LazyGit command
    };
  };
}
