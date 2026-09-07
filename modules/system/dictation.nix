{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.qgroget.nixos.dictation;
in {
  # System-side of the universal voice dictation (issue #48).
  #
  # This module only provisions the low-level plumbing the user-space toggle
  # agent (home/scripts/dictation.sh, wired via home.nix) relies on:
  #   1. `programs.ydotool` — starts the `ydotoold` system service and exposes
  #      /dev/uinput to the `ydotool` group, so the agent can inject keystrokes
  #      into the focused Wayland window WITHOUT root/sudo at runtime.
  #   2. Puts the primary user into the `ydotool` group.
  #      (The module itself exports YDOTOOL_SOCKET for graphical sessions.)
  #
  # Gated behind qgroget.nixos.dictation (opt-in, default off).

  config = lib.mkIf cfg {
    programs.ydotool = {
      enable = true;
      # Members of this group may use `ydotool`. The module creates the group
      # and the hardened `ydotoold` system service for us.
      group = "ydotool";
    };

    users.users.${config.qgroget.user.username}.extraGroups = ["ydotool"];
  };
}
