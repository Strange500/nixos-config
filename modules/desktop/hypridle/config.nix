{
  pkgs,
  config,
  ...
}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "notify-send -u critical -t 5000 \"Screen Lock Warning\" \"Screen will lock in 10 seconds due to inactivity\" ";
      };

      listener = [
        {
          timeout = 290;
          on-timeout = "notify-send -u critical -t 5000 \"Screen Lock Warning\" \"Screen will lock in 10 seconds due to inactivity\" ";
        }
        {
          timeout = 300;
          on-timeout = "pidof hyprlock || hyprlock";
        }
      ];
    };
  };
}
