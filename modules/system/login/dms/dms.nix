{
  config,
  ...
}: {
  # nixpkgs renamed services.displayManager.dms-greeter -> dux-greeter.
  services.displayManager.dux-greeter = {
    enable = true;
    compositor.name = "niri"; # Or "hyprland" or "sway"
    # `configFiles` dropped: it is `listOf types.path` now (a list of plain
    # strings fails eval) and it is redundant with `configHome`, which already
    # pulls ~/.config/DankMaterialShell/settings.json (plus the .config/dms
    # fallbacks) into the greeter cache.
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
    configHome = "/home/${config.qgroget.user.username}";
  };
}
