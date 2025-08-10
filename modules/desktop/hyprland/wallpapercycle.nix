{pkgs, ...}: let
  wallpaper_script = ''
    #!/bin/bash
    # Simple wallpaper script with basic error handling and logging

    WAIT=300
    dir="$1"
    trans_type="any"
    LOG_FILE="$HOME/.local/share/wallpaper.log"

    # Simple logging
    log() {
        echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
    }

    # Check directory
    if [ ! -d "$dir" ]; then
        log "ERROR: Directory '$dir' not found"
        exit 1
    fi

    # Start daemon function
    start_daemon() {
        pkill -f "swww-daemon" 2>/dev/null
        sleep 1
        swww-daemon &
        sleep 2
        log "Started swww-daemon"
    }

    # Check if daemon is running
    daemon_running() {
        pgrep -f "swww-daemon" >/dev/null
    }

    # Set wallpaper function
    set_wallpaper() {
        if ! daemon_running; then
            log "Daemon not running, restarting..."
            start_daemon
        fi

        for dp in $(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}'); do
            BG="$(find "$dir" -name '*.jpg' -o -name '*.png' -o -name '*.gif' | shuf -n1)"
            if [ -n "$BG" ]; then
                swww img "$BG" --transition-fps 244 --transition-type "$trans_type" --transition-duration 1 -o "$dp" 2>/dev/null
                log "Set wallpaper for $dp: $(basename "$BG")"
            fi
            sleep 1
        done
    }

    # Cleanup on exit
    cleanup() {
        log "Stopping..."
        pkill -f "swww-daemon" 2>/dev/null
        exit 0
    }
    trap cleanup SIGINT SIGTERM

    # Start
    log "Starting wallpaper cycle"
    start_daemon

    # Main loop
    while true; do
        initial_monitors=$(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}')
        set_wallpaper

        for ((i=1; i<=WAIT; i++)); do
            current_monitors=$(hyprctl monitors | grep Monitor | awk -F'[ (]' '{print $2}')
            if [ "$initial_monitors" != "$current_monitors" ]; then
                log "Monitor changed"
                break
            fi
            sleep 1
        done
    done
  '';
in
  pkgs.writeShellScript "wallpaper-cycle" wallpaper_script
