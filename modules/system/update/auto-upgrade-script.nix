{pkgs,config, ...}: let
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

    if [ -z "${cfg.confDir}" ]; then
    	echo "Flake directory not specified. Use '--flake <path>' or set \$FLAKE_DIR."
    	exit 1
    fi

    cd "${cfg.confDir}"
    echo "$(sudo -u ${cfg.user} whoami) is running the script in ${cfg.confDir}"

    echo "Pulling the latest version of the repository..."
    /run/wrappers/bin/sudo -u ${cfg.user} git pull

    if [ ${cfg.pushUpdates} = true ]; then
    	echo "Updating flake.lock..."
    	/run/wrappers/bin/sudo -u ${cfg.user} nix flake update --commit-lock-file && /run/wrappers/bin/sudo -u ${cfg.user} git push
    else
    	echo "Skipping 'nix flake update'..."
    fi

    options="--flake "${cfg.confDir}" --use-remote-sudo"

    echo "Running this operation: nixos-rebuild ${cfg.operation} $options"
    /run/wrappers/bin/sudo -u root /run/current-system/sw/bin/nixos-rebuild ${cfg.operation} $options

    exit 0
  ''
