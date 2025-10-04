{
  pkgs,
  config,
  ...
}:
pkgs.writeShellApplication {
  name = "qgroget-auto-install-firtgirl";

  runtimeInputs = with pkgs; [
    coreutils
    steam-run
    proton-ge-bin
    pkgsi686Linux.freetype
    xvfb-run
    freetype
  ];

  text = ''
    set -euo pipefail

    echo "=== Auto Game Installer ==="
    echo "Timestamp: $(date)"

    INSTALLER=$1
    if [ -z "$INSTALLER" ]; then
      echo "Usage: auto-install-game <path-to-installer.exe>"
      exit 1
    fi

    echo "→ Installer path: $INSTALLER"

    if [ ! -f "$INSTALLER" ]; then
      echo "❌ Error: Installer file not found: $INSTALLER"
      exit 1
    fi

    GAME_NAME=$(basename "$(dirname "$INSTALLER")" | sed 's/\[FitGirl Repack\]//g' | xargs)
    echo "→ Game name: $GAME_NAME"

    # cd to the directory of the installer
    INSTALLER_DIR="$(dirname "$INSTALLER")"
    echo "→ Changing to installer directory: $INSTALLER_DIR"
    cd "$INSTALLER_DIR" || exit 1
    echo "✓ Current directory: $(pwd)"

    INSTALL_DIR="$HOME/install"
    TARGET_DIR="$INSTALL_DIR/$GAME_NAME"
    echo "→ Target installation directory: $TARGET_DIR"

    mkdir -p "$TARGET_DIR"
    echo "✓ Created target directory"

    PROTON="/run/current-system/sw/bin/proton"
    echo "→ Proton path: $PROTON"

    if [ ! -x "$PROTON" ]; then
      echo "❌ Error: Proton not found or not executable at $PROTON"
      exit 1
    fi
    echo "✓ Proton executable found"

    # Proton prefix location
    PROTON_PREFIX="$HOME/proton-prefixes/$GAME_NAME"
    echo "→ Proton prefix: $PROTON_PREFIX"
    mkdir -p "$PROTON_PREFIX"
    echo "✓ Created Proton prefix directory"
    mkdir -p "/home/${config.qgroget.user.username}/proton-prefixes/test/"

    echo ""
    echo "=== Starting Installation ==="
    echo "→ STEAM_COMPAT_CLIENT_INSTALL_PATH: $HOME/.steam/steam"
    echo "→ STEAM_COMPAT_DATA_PATH: $PROTON_PREFIX"
    echo "→ LD_LIBRARY_PATH additions: ${pkgs.pkgsi686Linux.freetype}/lib:${pkgs.freetype}/lib"
    echo "→ Install location (Windows path): Z:$TARGET_DIR"
    echo ""

    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam"
    export STEAM_COMPAT_DATA_PATH="$PROTON_PREFIX"
    export LD_LIBRARY_PATH="${pkgs.pkgsi686Linux.freetype}/lib:${pkgs.freetype}/lib"

    echo "STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_COMPAT_CLIENT_INSTALL_PATH"
    echo "STEAM_COMPAT_DATA_PATH=$STEAM_COMPAT_DATA_PATH"
    echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo "✓ Environment variables set"

    # Run installer with Proton inside Steam runtime (backgrounded)
    COMMAND="xvfb-run -a steam-run proton run \"$INSTALLER\" \
      /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL /SP- \
      /COMPONENTS=\"\" /TASKS=\"\" \"/DIR=Z:$TARGET_DIR\""

    echo "→ Running command: $COMMAND"
    eval "$COMMAND" &
    INSTALL_PID=$!

    echo "→ Installer running with PID: $INSTALL_PID"
    echo ""
    sleep 30 # initial wait before checking
    echo "=== Monitoring install progress (directory changes) ==="

    prev_hash=""
    stable_count=0

    while true; do
      # Compute a hash of all files in the target dir (size + mtime + names)
      current_hash=$(find "$TARGET_DIR" -type f -printf "%p %s %T@\n" 2>/dev/null | sort | sha256sum | cut -d' ' -f1)

      if [ "$current_hash" = "$prev_hash" ]; then
        stable_count=$((stable_count + 1))
        echo "→ No changes detected ($stable_count/3)"
      else
        stable_count=0
        echo "→ Changes detected, resetting stability counter"
      fi

      prev_hash="$current_hash"

      # Require 3 consecutive stable checks (e.g. 3 × 20s = 1 minute of inactivity)
      if [ $stable_count -ge 3 ]; then
        echo "✓ No changes in $TARGET_DIR for a while, assuming installation finished."
        break
      fi

      sleep 20
    done


    echo "→ Killing installer process: $INSTALL_PID"
    kill "$INSTALL_PID" 2>/dev/null || true
    wait "$INSTALL_PID" 2>/dev/null || true

    echo ""
    echo "=== Installation Complete ==="
    echo "→ Installation directory: $TARGET_DIR"
    echo "→ Proton prefix: $PROTON_PREFIX"
    echo ""
    echo "Files installed:"
    ls -lh "$TARGET_DIR" 2>/dev/null || echo "  (unable to list files)"
    echo "Please run qgroget-steam-import \"$GAME_NAME\" \"GAME EXE\" \"$TARGET_DIR\" to add the game to Steam."
    echo "Replace \"GAME EXE\" with the actual game executable name."
    echo ""
    echo "============================"
  '';
}
