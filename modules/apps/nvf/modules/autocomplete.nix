{pkgs, ...}: {
  vim = {
    # 1. Install the manual plugin
    extraPlugins = {
      blink-cmp-copilot = {
        package = pkgs.vimPlugins.blink-cmp-copilot;
      };
    };

    # 2. Configure Blink to use Copilot
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

    # 3. Configure Copilot itself
    assistant.copilot = {
      enable = true;
      setupOpts = {
        suggestion.enabled = true;
        panel.enabled = true;
        panel.layout.position = "bottom";
      };
      # suggestion.enable = false; # Optional: Disable ghost text if it conflicts
    };
  };
}
