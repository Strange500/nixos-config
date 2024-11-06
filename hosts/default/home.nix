{ config, pkgs, ... }:

let
    monitorConfig = [
      {
        name = "DP-1";
        primary = true;
        width = 2560;
        height = 1440;
        refreshRate = 60;
        position = "auto";
        enabled = true;
        workspace = "1";
      }
      {
        name = "HDMI-A-1";
        primary = false;
        width = 1920;
        height = 1080;
        refreshRate = 60;
        position = "auto";
        enabled = true;
        workspace = "2";
      }
   ];
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.

  imports = [
    ../../home.nix
  ];

  monitors = monitorConfig;  # Include the monitor config here.



  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/strange/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

}
