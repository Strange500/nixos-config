{lib, ...}: {
  programs.kitty = {
    enable = true;

    font = lib.mkDefault {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };

    extraConfig = "include dank-tabs.conf\ninclude dank-theme.conf";

    settings = {
      background_opacity = lib.mkForce "0.90";
      background_blur = 8;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;

      tab_title_index = "{index} {tab.active_exe}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
    };

    keybindings = {
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
    };
  };
}
