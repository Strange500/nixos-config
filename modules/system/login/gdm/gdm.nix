{...}: {
  services.displayManager.gdm = {
    wayland = true;
    enable = true;
  };
}
