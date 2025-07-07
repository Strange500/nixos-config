{
  pkgs,
  config,
  ...
}: let
  cfg = {
    operation = "switch";
    confDir = "/home/${config.qgroget.user.username}/nixos";
    user = "${config.qgroget.user.username}";
    pushUpdates = "true";
    extraFlags = "";
    onCalendar = "daily";
    persistent = "true";
  };
in
  pkgs.writeShellScriptBin "auto-upgrade-script" ''
    # Wrapper script for nixos-rebuild

    notif_send() {
      local title="$1"
      local message="$2"
      local urgency="$3"
      # Detect the name of the display in use
      local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

      # Detect the user using such display
      local user=$(who | grep "($display)" | awk '{print $1}' | head -n 1)

      # Detect the id of the user
      local uid=$(id -u "${config.qgroget.user.username}")

      sudo -u "${config.qgroget.user.username}" DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" ${pkgs.libnotify}/bin/notify-send \
      --urgency="$urgency" \
      "$title" \
      "$message"
    }


    notif_send "NixOS Upgrade" "Starting NixOS upgrade process..." "normal"
    if [ -z "${cfg.confDir}" ]; then
    	echo "Flake directory not specified. Use '--flake <path>' or set \$FLAKE_DIR."
    	exit 1
    fi

    cd "${cfg.confDir}" || {
      echo "Failed to change directory to ${cfg.confDir}. Please check the path."
      exit 1
    }
    echo "Pulling the latest version of the repository..."
    notif_send "NixOS Upgrade" "Pulling the latest version of the repository..." "normal"
    /run/wrappers/bin/sudo -u ${cfg.user} ${pkgs.git}/bin/git pull

    if [ ${cfg.pushUpdates} = true ]; then
    	echo "Updating flake.lock..."
    	/run/wrappers/bin/sudo -u ${cfg.user} nix flake update --commit-lock-file && /run/wrappers/bin/sudo -u ${cfg.user} ${pkgs.git}/bin/git push
    else
    	echo "Skipping 'nix flake update'..."
    fi

    options="--flake "${cfg.confDir}" --use-remote-sudo"

    echo "Running this operation: nixos-rebuild ${cfg.operation} $options"
    notif_send "NixOS Upgrade" "Running nixos-rebuild ${cfg.operation} $options" "normal"
    /run/wrappers/bin/sudo -u root /run/current-system/sw/bin/nixos-rebuild ${cfg.operation} $options
    notif_send "NixOS Upgrade" "NixOS upgrade completed successfully!" "normal"

    exit 0
  ''
